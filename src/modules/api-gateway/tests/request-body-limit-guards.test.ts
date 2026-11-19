import { describe, expect, it } from "vitest";
import {
  POST_METHOD,
  PREFLIGHT_METHOD,
  PREFLIGHT_STATUS,
  REFUSED_TOKEN_STATUS,
  VERIFIED_AUTHORIZATION,
  protectedGuardAnswers,
  publicGuardAnswers,
} from "./jwt-support";
import {
  CHUNKED_ENCODING,
  LENGTH_REQUIRED_STATUS,
  MAX_REQUEST_BODY_BYTES,
  PAYLOAD_TOO_LARGE_STATUS,
  requestCarrying,
} from "./request-body-support";

const LARGEST_PERMITTED_LENGTH = String(MAX_REQUEST_BODY_BYTES);
const SMALLEST_OVERSIZED_LENGTH = String(MAX_REQUEST_BODY_BYTES + 1);
const EMPTY_BODY_LENGTH = "0";

describe("guardPublicRoute body limit", () => {
  it("lets through a body of exactly the maximum size", () => {
    const request = requestCarrying(POST_METHOD, {
      contentLength: LARGEST_PERMITTED_LENGTH,
    });

    expect(publicGuardAnswers(request)).toEqual([]);
  });

  it("refuses a body one byte over the maximum with 413", () => {
    const request = requestCarrying(POST_METHOD, {
      contentLength: SMALLEST_OVERSIZED_LENGTH,
    });

    expect(publicGuardAnswers(request)).toEqual([[PAYLOAD_TOO_LARGE_STATUS]]);
  });

  it("lets through an empty body", () => {
    const request = requestCarrying(POST_METHOD, {
      contentLength: EMPTY_BODY_LENGTH,
    });

    expect(publicGuardAnswers(request)).toEqual([]);
  });

  it("demands a length from a chunked body with 411", () => {
    const request = requestCarrying(POST_METHOD, {
      transferEncoding: CHUNKED_ENCODING,
    });

    expect(publicGuardAnswers(request)).toEqual([[LENGTH_REQUIRED_STATUS]]);
  });

  it("demands a length from a chunked body that also states one", () => {
    const request = requestCarrying(POST_METHOD, {
      contentLength: LARGEST_PERMITTED_LENGTH,
      transferEncoding: CHUNKED_ENCODING,
    });

    expect(publicGuardAnswers(request)).toEqual([[LENGTH_REQUIRED_STATUS]]);
  });

  it("lets through a request with no body headers at all", () => {
    const request = requestCarrying(POST_METHOD, {});

    expect(publicGuardAnswers(request)).toEqual([]);
  });

  it("answers an oversized chunked preflight with 204 alone", () => {
    const request = requestCarrying(PREFLIGHT_METHOD, {
      contentLength: SMALLEST_OVERSIZED_LENGTH,
      transferEncoding: CHUNKED_ENCODING,
    });

    expect(publicGuardAnswers(request)).toEqual([[PREFLIGHT_STATUS]]);
  });
});

describe("guardProtectedRoute body limit", () => {
  it("lets a signed-in body of exactly the maximum size through", () => {
    const request = requestCarrying(
      POST_METHOD,
      { contentLength: LARGEST_PERMITTED_LENGTH },
      VERIFIED_AUTHORIZATION,
    );

    expect(protectedGuardAnswers(request)).toEqual([]);
  });

  it("refuses a signed-in body one byte over the maximum with 413", () => {
    const request = requestCarrying(
      POST_METHOD,
      { contentLength: SMALLEST_OVERSIZED_LENGTH },
      VERIFIED_AUTHORIZATION,
    );

    expect(protectedGuardAnswers(request)).toEqual([
      [PAYLOAD_TOO_LARGE_STATUS],
    ]);
  });

  it("refuses an anonymous oversized body with 413, not 401", () => {
    const request = requestCarrying(POST_METHOD, {
      contentLength: SMALLEST_OVERSIZED_LENGTH,
    });

    expect(protectedGuardAnswers(request)).toEqual([
      [PAYLOAD_TOO_LARGE_STATUS],
    ]);
  });

  it("demands a length from an anonymous chunked body, not a token", () => {
    const request = requestCarrying(POST_METHOD, {
      transferEncoding: CHUNKED_ENCODING,
    });

    expect(protectedGuardAnswers(request)).toEqual([
      [LENGTH_REQUIRED_STATUS],
    ]);
  });

  it("demands a length from a signed-in chunked body", () => {
    const request = requestCarrying(
      POST_METHOD,
      { transferEncoding: CHUNKED_ENCODING },
      VERIFIED_AUTHORIZATION,
    );

    expect(protectedGuardAnswers(request)).toEqual([
      [LENGTH_REQUIRED_STATUS],
    ]);
  });

  it("lets a signed-in request with no body headers through", () => {
    const request = requestCarrying(POST_METHOD, {}, VERIFIED_AUTHORIZATION);

    expect(protectedGuardAnswers(request)).toEqual([]);
  });

  it("still refuses an anonymous body within the limit with 401", () => {
    const request = requestCarrying(POST_METHOD, {
      contentLength: LARGEST_PERMITTED_LENGTH,
    });

    expect(protectedGuardAnswers(request)).toEqual([[REFUSED_TOKEN_STATUS]]);
  });

  it("answers an anonymous oversized chunked preflight with 204", () => {
    const request = requestCarrying(PREFLIGHT_METHOD, {
      contentLength: SMALLEST_OVERSIZED_LENGTH,
      transferEncoding: CHUNKED_ENCODING,
    });

    expect(protectedGuardAnswers(request)).toEqual([[PREFLIGHT_STATUS]]);
  });
});
