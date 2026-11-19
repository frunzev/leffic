import { describe, expect, it } from "vitest";
import fc from "fast-check";
import {
  POST_METHOD,
  PREFLIGHT_METHOD,
  PREFLIGHT_STATUS,
  nonPreflightMethodArbitrary,
  publicGuardAnswers,
} from "./jwt-support";
import {
  LENGTH_REQUIRED_STATUS,
  MAX_REQUEST_BODY_BYTES,
  PAYLOAD_TOO_LARGE_STATUS,
  anyLengthOrNoneArbitrary,
  oversizedLengthArbitrary,
  permittedLengthArbitrary,
  requestCarrying,
  transferEncodingArbitrary,
  transferEncodingOrNoneArbitrary,
} from "./request-body-support";

const WIDEST_PROBED_LENGTH = 2 * MAX_REQUEST_BODY_BYTES;

describe("guardPublicRoute body limit properties", () => {
  it("guardPublicRoute property refuses every oversized body with 413", () => {
    fc.assert(
      fc.property(
        nonPreflightMethodArbitrary,
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

  it("guardPublicRoute property passes every body within the limit", () => {
    fc.assert(
      fc.property(
        nonPreflightMethodArbitrary,
        permittedLengthArbitrary,
        (method, contentLength) => {
          const request = requestCarrying(method, { contentLength });

          expect(publicGuardAnswers(request)).toEqual([]);
        },
      ),
    );
  });

  it("guardPublicRoute property demands a length for any encoding", () => {
    fc.assert(
      fc.property(
        nonPreflightMethodArbitrary,
        transferEncodingArbitrary,
        anyLengthOrNoneArbitrary,
        (method, transferEncoding, contentLength) => {
          const request = requestCarrying(method, {
            transferEncoding,
            contentLength,
          });

          expect(publicGuardAnswers(request)).toEqual([
            [LENGTH_REQUIRED_STATUS],
          ]);
        },
      ),
    );
  });

  it("guardPublicRoute property answers a preflight 204 whatever body", () => {
    fc.assert(
      fc.property(
        anyLengthOrNoneArbitrary,
        transferEncodingOrNoneArbitrary,
        (contentLength, transferEncoding) => {
          const request = requestCarrying(PREFLIGHT_METHOD, {
            contentLength,
            transferEncoding,
          });

          expect(publicGuardAnswers(request)).toEqual([[PREFLIGHT_STATUS]]);
        },
      ),
    );
  });

  it("guardPublicRoute property passes a length iff it is within max", () => {
    fc.assert(
      fc.property(
        fc.integer({ min: 0, max: WIDEST_PROBED_LENGTH }),
        (length) => {
          const request = requestCarrying(POST_METHOD, {
            contentLength: String(length),
          });
          const isPassed = publicGuardAnswers(request).length === 0;

          expect(isPassed).toBe(length <= MAX_REQUEST_BODY_BYTES);
        },
      ),
    );
  });
});
