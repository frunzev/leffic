import crypto from "crypto";
import { expect, vi } from "vitest";
import {
  FAR_FUTURE,
  SECRET,
  SECRET_VARIABLE,
  VERIFIED_AUTHORIZATION,
  type FakeRequest,
  bearerAuthorization,
  protectedGuardAnswers,
  requestWith,
  signedWith,
} from "../jwt-support";
import type { GatewayStepDefinition } from "./gateway-steps";

const UNREADABLE_CLAIMS = "not json at all";
const TOKEN_HEADER = { alg: "HS256" };
const NON_BEARER_AUTHORIZATION = "Basic bGVhcm5lcjpwYXNzd29yZA==";
const SINGLE_PART_AUTHORIZATION = "Bearer onlyonepart";

function signedRequest(claims: Record<string, unknown>): FakeRequest {
  return requestWith(bearerAuthorization(signedWith(claims)));
}

function base64url(text: string): string {
  return Buffer.from(text).toString("base64url");
}

function unreadableClaimsRequest(): FakeRequest {
  const header = base64url(JSON.stringify(TOKEN_HEADER));
  const claims = base64url(UNREADABLE_CLAIMS);
  const signingInput = `${header}.${claims}`;
  const signature = crypto
    .createHmac("sha256", SECRET)
    .update(signingInput)
    .digest("base64url");

  return requestWith(bearerAuthorization(`${signingInput}.${signature}`));
}

export const signInStepDefinitions: readonly GatewayStepDefinition[] = [
  {
    keyword: "When",
    pattern:
      /^a content request reaches the gateway with a sign-in that never expires$/,
    action: (world) => {
      world.answers = protectedGuardAnswers(signedRequest({}));
    },
  },
  {
    keyword: "When",
    pattern:
      /^a content request reaches the gateway with a sign-in whose claims cannot be read$/,
    action: (world) => {
      world.answers = protectedGuardAnswers(unreadableClaimsRequest());
    },
  },
  {
    keyword: "When",
    pattern:
      /^a content request reaches the gateway with a sign-in that is not a bearer sign-in$/,
    action: (world) => {
      const request = requestWith(NON_BEARER_AUTHORIZATION);
      world.answers = protectedGuardAnswers(request);
    },
  },
  {
    keyword: "When",
    pattern: /^a content request reaches the gateway with a cut-short signature$/,
    action: (world) => {
      const token = signedWith({ exp: FAR_FUTURE });
      const cutShort = token.slice(0, -1);
      world.answers = protectedGuardAnswers(
        requestWith(bearerAuthorization(cutShort)),
      );
    },
  },
  {
    keyword: "When",
    pattern:
      /^a content request reaches the gateway with a sign-in token of a single part$/,
    action: (world) => {
      const request = requestWith(SINGLE_PART_AUTHORIZATION);
      world.answers = protectedGuardAnswers(request);
    },
  },
  {
    keyword: "When",
    pattern: /^a content request reaches a gateway that has no signing secret$/,
    action: (world) => {
      vi.stubEnv(SECRET_VARIABLE, undefined);
      const request = requestWith(VERIFIED_AUTHORIZATION);
      world.answers = protectedGuardAnswers(request);
      world.errors = request.error.mock.calls;
    },
  },
  {
    keyword: "Then",
    pattern: /^the gateway logs "(.+)"$/,
    action: (world, values) => {
      expect(world.errors).toEqual([[values[0]]]);
    },
  },
];
