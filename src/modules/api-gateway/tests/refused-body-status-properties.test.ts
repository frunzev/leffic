import { describe, expect, it } from "vitest";
import fc from "fast-check";
import {
  nonPreflightMethodArbitrary,
  publicGuardAnswers,
} from "./jwt-support";
import {
  LENGTH_REQUIRED_STATUS,
  MAX_REQUEST_BODY_BYTES,
  PAYLOAD_TOO_LARGE_STATUS,
  anyLengthOrNoneArbitrary,
  requestCarrying,
  transferEncodingOrNoneArbitrary,
} from "./request-body-support";

function expectedRefusal(
  transferEncoding: string | undefined,
  contentLength: string | undefined,
): number[][] {
  if (transferEncoding !== undefined) {
    return [[LENGTH_REQUIRED_STATUS]];
  }

  if (Number(contentLength) > MAX_REQUEST_BODY_BYTES) {
    return [[PAYLOAD_TOO_LARGE_STATUS]];
  }

  return [];
}

describe("refusedBodyStatus properties", () => {
  it("refusedBodyStatus property ranks a missing length above any size", () => {
    fc.assert(
      fc.property(
        nonPreflightMethodArbitrary,
        transferEncodingOrNoneArbitrary,
        anyLengthOrNoneArbitrary,
        (method, transferEncoding, contentLength) => {
          const request = requestCarrying(method, {
            transferEncoding,
            contentLength,
          });

          expect(publicGuardAnswers(request)).toEqual(
            expectedRefusal(transferEncoding, contentLength),
          );
        },
      ),
    );
  });
});
