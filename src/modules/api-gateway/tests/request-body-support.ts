import fc from "fast-check";
import {
  FakeRequest,
  RequestHeaders,
  VERIFIED_AUTHORIZATION,
  foreignTokenArbitrary,
  bearerAuthorization,
  requestUsing,
  signedWith,
  LONG_PAST,
} from "./jwt-support";

export const MAX_REQUEST_BODY_BYTES = 104_857_600;
export const PAYLOAD_TOO_LARGE_STATUS = 413;
export const LENGTH_REQUIRED_STATUS = 411;
export const CHUNKED_ENCODING = "chunked";

type BodyHeaders = {
  readonly contentLength?: string;
  readonly transferEncoding?: string;
};

const LARGEST_EXACT_LENGTH = Number.MAX_SAFE_INTEGER;
const COMMON_TRANSFER_ENCODINGS = ["chunked", "gzip, chunked", "identity"];

function bodyHeadersIn(bodyHeaders: BodyHeaders): RequestHeaders {
  const headersIn: RequestHeaders = {};

  if (bodyHeaders.contentLength !== undefined) {
    headersIn["Content-Length"] = bodyHeaders.contentLength;
  }

  if (bodyHeaders.transferEncoding !== undefined) {
    headersIn["Transfer-Encoding"] = bodyHeaders.transferEncoding;
  }

  return headersIn;
}

export function requestCarrying(
  method: string,
  bodyHeaders: BodyHeaders,
  authorization?: string,
): FakeRequest {
  const request = requestUsing(method, authorization);
  const headersIn = {
    ...request.headersIn,
    ...bodyHeadersIn(bodyHeaders),
  };

  return { ...request, headersIn };
}

export const oversizedLengthArbitrary = fc
  .integer({ min: MAX_REQUEST_BODY_BYTES + 1, max: LARGEST_EXACT_LENGTH })
  .map(String);

export const permittedLengthArbitrary = fc
  .integer({ min: 0, max: MAX_REQUEST_BODY_BYTES })
  .map(String);

export const anyLengthOrNoneArbitrary = fc.option(
  fc.oneof(permittedLengthArbitrary, oversizedLengthArbitrary),
  { nil: undefined },
);

export const transferEncodingArbitrary = fc.oneof(
  fc.constantFrom(...COMMON_TRANSFER_ENCODINGS),
  fc.string(),
);

export const transferEncodingOrNoneArbitrary = fc.option(
  transferEncodingArbitrary,
  { nil: undefined },
);

const expiredAuthorization = bearerAuthorization(
  signedWith({ exp: LONG_PAST }),
);

export const refusedAuthorizationArbitrary = fc.option(
  fc.oneof(
    fc.string(),
    fc.constant(expiredAuthorization),
    foreignTokenArbitrary.map(bearerAuthorization),
  ),
  { nil: undefined },
).filter((authorization) => authorization !== VERIFIED_AUTHORIZATION);

export const anyAuthorizationArbitrary = fc.oneof(
  refusedAuthorizationArbitrary,
  fc.constant(VERIFIED_AUTHORIZATION),
);
