import { describe, expect, it } from "vitest";
import jwt from "../src/jwt";
import { njsModuleText } from "./nginx-config-support";
import {
  POST_METHOD,
  PREFLIGHT_METHOD,
  PREFLIGHT_STATUS,
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

const BODY_LIMIT_NAME = "MAX_REQUEST_BODY_BYTES";
const BODY_LIMIT_DECLARATION =
  "const MAX_REQUEST_BODY_BYTES = 100 * 1024 * 1024;";
const LENGTH_REQUIRED_DECLARATION = "const LENGTH_REQUIRED_STATUS = 411;";
const PAYLOAD_TOO_LARGE_DECLARATION = /^const [A-Z][A-Z_]* = 413;$/m;
const PAYLOAD_TOO_LARGE_LITERAL = /\b413\b/g;
const BODY_LIMIT_OCCURRENCES_WITH_ONE_COMPARISON = 2;
const EXPORTED_GUARD_NAMES = ["guardProtectedRoute", "guardPublicRoute"];
const FUNCTION_TYPE = "function";
const UPLOAD_OF_EXACTLY_THE_LIMIT = String(MAX_REQUEST_BODY_BYTES);
const UPLOAD_ONE_BYTE_OVER_THE_LIMIT = String(MAX_REQUEST_BODY_BYTES + 1);

function occurrencesOf(source: string, text: string): number {
  return source.split(text).length - 1;
}

describe("the njs module declares the body limit it enforces", () => {
  it("caps a request body at one hundred mebibytes", () => {
    expect(njsModuleText()).toContain(BODY_LIMIT_DECLARATION);
  });

  it("names the length-required status as a constant", () => {
    expect(njsModuleText()).toContain(LENGTH_REQUIRED_DECLARATION);
  });

  it("names the payload-too-large status as a constant", () => {
    expect(njsModuleText()).toMatch(PAYLOAD_TOO_LARGE_DECLARATION);
  });

  it("writes the payload-too-large status nowhere but its constant", () => {
    const literals = njsModuleText().match(PAYLOAD_TOO_LARGE_LITERAL) ?? [];

    expect(literals.length).toBe(1);
  });

  it("compares a body against the limit in exactly one place", () => {
    const occurrences = occurrencesOf(njsModuleText(), BODY_LIMIT_NAME);

    expect(occurrences).toBe(BODY_LIMIT_OCCURRENCES_WITH_ONE_COMPARISON);
  });

  it("exposes exactly the two guards to nginx and no body helper", () => {
    const exportedNames = Object.keys(jwt).sort();

    expect(exportedNames).toEqual(EXPORTED_GUARD_NAMES);
    expect(typeof jwt.guardPublicRoute).toBe(FUNCTION_TYPE);
    expect(typeof jwt.guardProtectedRoute).toBe(FUNCTION_TYPE);
  });
});

describe("a learner's upload through the real guards", () => {
  it("lets a signed-in upload of exactly the limit reach the service", () => {
    const request = requestCarrying(
      POST_METHOD,
      { contentLength: UPLOAD_OF_EXACTLY_THE_LIMIT },
      VERIFIED_AUTHORIZATION,
    );

    expect(protectedGuardAnswers(request)).toEqual([]);
  });

  it("stops a signed-in upload one byte over the limit with 413", () => {
    const request = requestCarrying(
      POST_METHOD,
      { contentLength: UPLOAD_ONE_BYTE_OVER_THE_LIMIT },
      VERIFIED_AUTHORIZATION,
    );

    expect(protectedGuardAnswers(request)).toEqual([
      [PAYLOAD_TOO_LARGE_STATUS],
    ]);
  });

  it("stops an anonymous chunked upload with 411 before any token", () => {
    const request = requestCarrying(POST_METHOD, {
      transferEncoding: CHUNKED_ENCODING,
    });

    expect(protectedGuardAnswers(request)).toEqual([
      [LENGTH_REQUIRED_STATUS],
    ]);
  });

  it("answers the browser's preflight for an oversized upload with 204", () => {
    const request = requestCarrying(PREFLIGHT_METHOD, {
      contentLength: UPLOAD_ONE_BYTE_OVER_THE_LIMIT,
    });

    expect(protectedGuardAnswers(request)).toEqual([[PREFLIGHT_STATUS]]);
  });

  it("lets a bodiless sign-in request reach the user service", () => {
    const request = requestCarrying(POST_METHOD, {});

    expect(publicGuardAnswers(request)).toEqual([]);
  });
});
