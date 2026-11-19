import { describe, expect, it } from "vitest";
import {
  CATCH_ALL_LOCATION,
  accessGuardsOf,
  requiredLocation,
} from "./gateway-location-support";
import { directivesNamed } from "./nginx-config-support";

const BODY_SIZE_DIRECTIVE = "client_max_body_size";
const UNLIMITED_BODY_SIZE = "0";

function catchAllBodySizeLimits(): readonly string[] {
  const catchAll = requiredLocation(CATCH_ALL_LOCATION);
  const locationLimits = catchAll.children
    .filter((directive) => directive.name === BODY_SIZE_DIRECTIVE)
    .map((directive) => directive.arguments[0] ?? "");
  const serverLimits = directivesNamed(BODY_SIZE_DIRECTIVE)
    .map((directive) => directive.arguments[0] ?? "");

  return locationLimits.length > 0 ? locationLimits : serverLimits;
}

describe("the unrouted catch-all location", () => {
  it("still bounds a request body by nginx or by a guard", () => {
    const effectiveLimit = catchAllBodySizeLimits()[0];
    const guards = accessGuardsOf(requiredLocation(CATCH_ALL_LOCATION));
    const isBodyBounded =
      effectiveLimit !== UNLIMITED_BODY_SIZE || guards.length > 0;

    expect(isBodyBounded).toBe(true);
  });
});
