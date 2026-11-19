import { describe, expect, it } from "vitest";
import fc from "fast-check";
import {
  PREFLIGHT_METHOD,
  PREFLIGHT_STATUS,
  REFUSED_TOKEN_STATUS,
  VERIFIED_AUTHORIZATION,
  authorizationOrNoneArbitrary,
  nonPreflightMethodArbitrary,
  protectedGuardAnswers,
  requestPartsArbitrary,
} from "./jwt-support";
import {
  LENGTH_REQUIRED_STATUS,
  PAYLOAD_TOO_LARGE_STATUS,
  anyAuthorizationArbitrary,
  anyLengthOrNoneArbitrary,
  oversizedLengthArbitrary,
  permittedLengthArbitrary,
  refusedAuthorizationArbitrary,
  requestCarrying,
  transferEncodingArbitrary,
  transferEncodingOrNoneArbitrary,
} from "./request-body-support";

const MOST_ANSWERS_PER_REQUEST = 1;

describe("guardProtectedRoute body limit properties", () => {
  it("guardProtectedRoute property refuses oversize 413 any token", () => {
    fc.assert(
      fc.property(
        nonPreflightMethodArbitrary,
        oversizedLengthArbitrary,
        anyAuthorizationArbitrary,
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

  it("guardProtectedRoute property passes a signed-in body in limit", () => {
    fc.assert(
      fc.property(
        nonPreflightMethodArbitrary,
        permittedLengthArbitrary,
        (method, contentLength) => {
          const request = requestCarrying(
            method,
            { contentLength },
            VERIFIED_AUTHORIZATION,
          );

          expect(protectedGuardAnswers(request)).toEqual([]);
        },
      ),
    );
  });

  it("guardProtectedRoute property demands a length any encoding", () => {
    fc.assert(
      fc.property(
        nonPreflightMethodArbitrary,
        transferEncodingArbitrary,
        anyAuthorizationArbitrary,
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

  it("guardProtectedRoute property answers a preflight 204 any body", () => {
    fc.assert(
      fc.property(
        anyLengthOrNoneArbitrary,
        transferEncodingOrNoneArbitrary,
        authorizationOrNoneArbitrary,
        (contentLength, transferEncoding, authorization) => {
          const request = requestCarrying(
            PREFLIGHT_METHOD,
            { contentLength, transferEncoding },
            authorization,
          );

          expect(protectedGuardAnswers(request)).toEqual([
            [PREFLIGHT_STATUS],
          ]);
        },
      ),
    );
  });

  it("guardProtectedRoute property never says 401 to an oversized body", () => {
    fc.assert(
      fc.property(
        nonPreflightMethodArbitrary,
        oversizedLengthArbitrary,
        refusedAuthorizationArbitrary,
        (method, contentLength, authorization) => {
          const request = requestCarrying(
            method,
            { contentLength },
            authorization,
          );
          const answers = protectedGuardAnswers(request);

          expect(answers).not.toContainEqual([REFUSED_TOKEN_STATUS]);
          expect(answers).toEqual([[PAYLOAD_TOO_LARGE_STATUS]]);
        },
      ),
    );
  });

  it("guardProtectedRoute property refuses no token in limit with 401", () => {
    fc.assert(
      fc.property(
        nonPreflightMethodArbitrary,
        permittedLengthArbitrary,
        refusedAuthorizationArbitrary,
        (method, contentLength, authorization) => {
          const request = requestCarrying(
            method,
            { contentLength },
            authorization,
          );

          expect(protectedGuardAnswers(request)).toEqual([
            [REFUSED_TOKEN_STATUS],
          ]);
        },
      ),
    );
  });

  it("guardProtectedRoute property answers any request at most once", () => {
    fc.assert(
      fc.property(
        requestPartsArbitrary,
        anyLengthOrNoneArbitrary,
        transferEncodingOrNoneArbitrary,
        ([method, authorization], contentLength, transferEncoding) => {
          const request = requestCarrying(
            method,
            { contentLength, transferEncoding },
            authorization,
          );
          const answers = protectedGuardAnswers(request);

          expect(answers.length).toBeLessThanOrEqual(MOST_ANSWERS_PER_REQUEST);
        },
      ),
    );
  });
});
