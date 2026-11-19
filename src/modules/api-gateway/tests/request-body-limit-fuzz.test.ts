import { describe, expect, it, vi } from "vitest";
import fc from "fast-check";
import {
  MISSING_SECRETS,
  POST_METHOD,
  PREFLIGHT_METHOD,
  PREFLIGHT_STATUS,
  SECRET_VARIABLE,
  VERIFIED_AUTHORIZATION,
  bearerAuthorization,
  binaryTextArbitrary,
  hostileMethodArbitrary,
  protectedGuardAnswers,
  publicGuardAnswers,
} from "./jwt-support";
import {
  LENGTH_REQUIRED_STATUS,
  MAX_REQUEST_BODY_BYTES,
  PAYLOAD_TOO_LARGE_STATUS,
  requestCarrying,
} from "./request-body-support";

const ASTRONOMICAL_DIGIT_COUNT = 40;
const ASTRONOMICAL_LENGTH = "9".repeat(ASTRONOMICAL_DIGIT_COUNT);
const LEADING_ZEROES = "0".repeat(ASTRONOMICAL_DIGIT_COUNT);
const OVERSIZED_LENGTHS = [
  String(MAX_REQUEST_BODY_BYTES + 1),
  String(Number.MAX_SAFE_INTEGER),
  "18446744073709551616",
  ASTRONOMICAL_LENGTH,
  `${LEADING_ZEROES}${MAX_REQUEST_BODY_BYTES + 1}`,
];
const PERMITTED_LENGTHS = [
  "0",
  "1",
  String(MAX_REQUEST_BODY_BYTES - 1),
  String(MAX_REQUEST_BODY_BYTES),
  `${LEADING_ZEROES}${MAX_REQUEST_BODY_BYTES}`,
];
const HOSTILE_ENCODINGS = [
  "",
  " ",
  "CHUNKED",
  "chunked, chunked",
  "\u0000",
  "\uD83D\uDCE6",
  "x".repeat(ASTRONOMICAL_DIGIT_COUNT),
];

const oversizedLengthArbitrary = fc.constantFrom(...OVERSIZED_LENGTHS);
const hostileEncodingArbitrary = fc.oneof(
  fc.constantFrom(...HOSTILE_ENCODINGS),
  binaryTextArbitrary,
);
const hostileAuthorizationArbitrary = fc.option(
  fc.oneof(binaryTextArbitrary, binaryTextArbitrary.map(bearerAuthorization)),
  { nil: undefined },
);

describe("body limit under hostile body headers", () => {
  it.each(OVERSIZED_LENGTHS)("refuses the length %s with 413", (length) => {
    const request = requestCarrying(POST_METHOD, { contentLength: length });

    expect(publicGuardAnswers(request)).toEqual([[PAYLOAD_TOO_LARGE_STATUS]]);
  });

  it.each(PERMITTED_LENGTHS)("lets the length %s through", (length) => {
    const request = requestCarrying(POST_METHOD, { contentLength: length });

    expect(publicGuardAnswers(request)).toEqual([]);
  });

  it.each(OVERSIZED_LENGTHS)("refuses an anonymous %s with 413", (length) => {
    const request = requestCarrying(POST_METHOD, { contentLength: length });

    expect(protectedGuardAnswers(request)).toEqual([
      [PAYLOAD_TOO_LARGE_STATUS],
    ]);
  });

  it.each(PERMITTED_LENGTHS)("passes a signed-in %s", (length) => {
    const request = requestCarrying(
      POST_METHOD,
      { contentLength: length },
      VERIFIED_AUTHORIZATION,
    );

    expect(protectedGuardAnswers(request)).toEqual([]);
  });

  it.each(HOSTILE_ENCODINGS)("demands a length for encoding %j", (value) => {
    const bodyHeaders = { transferEncoding: value };
    const publicRequest = requestCarrying(POST_METHOD, bodyHeaders);
    const protectedRequest = requestCarrying(POST_METHOD, bodyHeaders);

    expect(publicGuardAnswers(publicRequest)).toEqual([
      [LENGTH_REQUIRED_STATUS],
    ]);
    expect(protectedGuardAnswers(protectedRequest)).toEqual([
      [LENGTH_REQUIRED_STATUS],
    ]);
  });

  it("a near-miss preflight method gets 413, not 204", () => {
    fc.assert(
      fc.property(
        hostileMethodArbitrary,
        oversizedLengthArbitrary,
        (method, contentLength) => {
          const request = requestCarrying(method, { contentLength });

          expect(publicGuardAnswers(request)).toEqual([
            [PAYLOAD_TOO_LARGE_STATUS],
          ]);
        },
      ),
    );
  });

  it("a hostile token never turns an oversized body into 401", () => {
    fc.assert(
      fc.property(
        hostileMethodArbitrary,
        oversizedLengthArbitrary,
        hostileAuthorizationArbitrary,
        (method, contentLength, authorization) => {
          const request = requestCarrying(
            method,
            { contentLength },
            authorization,
          );

          expect(protectedGuardAnswers(request)).toEqual([
            [PAYLOAD_TOO_LARGE_STATUS],
          ]);
        },
      ),
    );
  });

  it("a hostile token never turns a hostile encoding into 401", () => {
    fc.assert(
      fc.property(
        hostileMethodArbitrary,
        hostileEncodingArbitrary,
        hostileAuthorizationArbitrary,
        (method, transferEncoding, authorization) => {
          const request = requestCarrying(
            method,
            { transferEncoding },
            authorization,
          );

          expect(protectedGuardAnswers(request)).toEqual([
            [LENGTH_REQUIRED_STATUS],
          ]);
        },
      ),
    );
  });

  it("any preflight is 204 however hostile its body headers", () => {
    fc.assert(
      fc.property(
        fc.option(oversizedLengthArbitrary, { nil: undefined }),
        fc.option(hostileEncodingArbitrary, { nil: undefined }),
        hostileAuthorizationArbitrary,
        (contentLength, transferEncoding, authorization) => {
          const request = requestCarrying(
            PREFLIGHT_METHOD,
            { contentLength, transferEncoding },
            authorization,
          );

          expect(publicGuardAnswers(request)).toEqual([[PREFLIGHT_STATUS]]);
        },
      ),
    );
  });

  it.each(MISSING_SECRETS)("refuses oversize 413 with secret %j", (secret) => {
    vi.stubEnv(SECRET_VARIABLE, secret);
    const request = requestCarrying(
      POST_METHOD,
      { contentLength: ASTRONOMICAL_LENGTH },
      VERIFIED_AUTHORIZATION,
    );

    expect(protectedGuardAnswers(request)).toEqual([
      [PAYLOAD_TOO_LARGE_STATUS],
    ]);
  });
});
