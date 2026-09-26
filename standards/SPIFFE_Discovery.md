# SPIFFE Discovery

> **Stability: Proposed** - see [STABILITY.md](STABILITY.md).

## Status of this Memo
This document specifies an identity API standard for the internet community, and requests discussion and suggestions for improvements. Distribution of this document is unlimited.

## 1. Background

In an interconnected world workloads often need to communicate with other workloads and resources outside of their trust domain. The [SPIFFE Federation](./SPIFFE_Federation.md) specification is available to retrieve SPIFFE Trust Bundles from other domains by configuring federation out of band. However, manual configuration is not always feasible on the internet and sometimes trust needs to be established at runtime.

## 2. Introduction

The SPIFFE Discovery specification defines a well-known endpoint and configuration document that consumers can use to discover SPIFFE Trust Domain metadata. Properties include information such as the SPIFFE Federation Endpoint & profile, signing algorithms in use and more. Participants can use this document to learn about the trust domain and verify SVIDs issued by it.

The well-known endpoint does not need to be configured out of band and can be computed from SPIFFE-IDs and SPIFFE Trust Domain Names.

## 2.1 Relationship to WIMSE 

TODO

## 3. Targeted Use Cases

TODO

## 4. Requirements

This document assumes that the SPIFFE Trust Domain Name is a fully-qualified domain name which is available in DNS and has a trusted TLS certificate available. The trust model that is associated with DNS and the web public key infrastructure becomes the base for discovery and with that the SPIFFE Trust Bundle too.

## 5. SPIFFE Trust Domain Discovery Endpoint

This section defines the location of the SPIFFE Trust Domain Discovery Endpoint and the requirements that apply to servers serving it and to clients consuming it.

### 5.1. Endpoint URL

The SPIFFE Trust Domain Discovery Endpoint is a well-known endpoint that can be computed from the Trust Domain Name. The URL of the endpoint is computed by using the `https://` URI scheme, the SPIFFE Trust Domain Name as the authority and `/.well-known/wimse-trust-domain` as the path. Other URI compoments such as user, fragments, port, or query parameters are not permitted. Request URIs that contains any non permitted components MUST be rejected.

For example, the SPIFFE Trust Domain of `spiffe://example.org` results in a SPIFFE Trust Domain Discovery Endpoint of `https://example.org/.well-known/wimse-trust-domain`.

Open topics/TODOs:
- sub-domains
- CNAME and other DNS mechaniscs
- What about redirect? Should we allow it? What about authority - TD name mismatch? Follow redirect but still require original dial target to be the trust domain name?

### 5.2. Serving the Discovery Endpoint

Servers use standard TLS-protected HTTP (i.e. HTTPS). The server certificate MUST be issued by a public certificate authority (as defined by the membership list of the CA/Browser forum) and MUST include the SPIFFE Trust Domain Name as an X.509 Subject Alternative Name. Servers MUST NOT require client authentication, at either the transport or the HTTP layer.

Upon receiving an HTTP `GET` for the well-known path, the server MUST respond with `200 OK` and the current [SPIFFE Trust Domain Configuration Document](#6-spiffe-trust-domain-configuration-document), encoded as UTF-8 with a `Content-Type` of `application/json`. Servers MUST NOT serve a document whose `spiffe_trust_domain_name` differs from the authority of the request URI, and MUST respond with `404 Not Found` if they do not serve a SPIFFE Trust Domain under that authority.

Servers SHOULD set `Cache-Control` and `ETag` headers, and SHOULD NOT set a `max-age` longer than the interval at which the document is expected to change.

### 5.3. Consuming the Discovery Endpoint

Clients use standard TLS-protected HTTP (i.e. HTTPS). The server certificate MUST be validated in accordance with [RFC 6125](https://tools.ietf.org/html/rfc6125) against the SPIFFE Trust Domain Name. Clients MUST NOT fall back to unauthenticated TLS or to plaintext HTTP.

Clients issue an HTTP `GET` for the [computed endpoint URL](#51-endpoint-url). Only a `200 OK` response carries a Configuration Document; any other status code MUST be treated as a failure to discover the trust domain. Clients MUST parse the body as a JSON object and MUST verify that `spiffe_trust_domain_name` equals the authority of the endpoint URL, as described in [6.1.1](#611-spiffe-trust-domain-name-spiffe_trust_domain_name).

Clients SHOULD honor the server's caching directives, SHOULD refresh the document periodically, and SHOULD retry failed retrievals with an exponential backoff.

TODOs:
- security considerations for caching

# 6. SPIFFE Trust Domain Configuration Document

The SPIFFE Trust Domain Configuration Document is a JSON document that is served at the SPIFFE Trust Domain Discovery Endpoint. It carries non-sensitive metadata of the SPIFFE Trust Domain.

The document MUST be a JSON object as defined by [RFC 8259](https://tools.ietf.org/html/rfc8259). Clients MUST reject a document that omits a REQUIRED property or that carries a property whose value is not of the specified type. Clients MUST ignore properties they do not recognize, so that properties can be added to this specification without breaking existing clients.

TODOs:
- other properties such as signing algorithms?
- Versioning?

## 6.1 Properties

| Property | Type | Presence |
| --- | --- | --- |
| [`spiffe_trust_domain_name`](#611-spiffe-trust-domain-name-spiffe_trust_domain_name) | string | REQUIRED |
| [`spiffe_bundle_endpoint_uri`](#612-spiffe-bundle-endpoint-uri-spiffe_bundle_endpoint_uri) | string | REQUIRED |
| [`spiffe_bundle_endpoint_profile`](#613-spiffe-bundle-endpoint-profile-spiffe_bundle_endpoint_profile) | string | REQUIRED |

### 6.1.1 SPIFFE Trust Domain Name (`spiffe_trust_domain_name`)

The `spiffe_trust_domain_name` property carries the SPIFFE Trust Domain Name. When served on the SPIFFE Trust Domain Discovery Endpoint it must be equal to the authority of the URI. Clients that observe a different SPIFFE Trust Domain Name MUST reject the document and MUST ensure that documents are not processed under the context of a different SPIFFE Trust Domain Name.

### 6.1.2 SPIFFE Bundle Endpoint URI (`spiffe_bundle_endpoint_uri`)

The `spiffe_bundle_endpoint_uri` property contains a URI pointing to the SPIFFE Bundle Endpoint as defined in [SPIFFE Federation](./SPIFFE_Federation.md). The URI MUST use the `https` scheme.

TODOs:
- Different domain?

### 6.1.3 SPIFFE Bundle Endpoint Profile (`spiffe_bundle_endpoint_profile`)

The `spiffe_bundle_endpoint_profile` property describes the Federation Endpoint profile as defined in [SPIFFE Federation](./SPIFFE_Federation.md).

Valid values are `https_web` and `https_spiffe`. Clients MUST reject a document that carries any other value.

TODOs:
- Only allow https_web?
- Describe valid values here or just link?
- `https_spiffe` requires an endpoint SPIFFE ID; add a property to carry it, or drop the profile?

## 6.2 Example

```json
{
  "spiffe_trust_domain_name": "example.org",
  "spiffe_bundle_endpoint_uri": "https://example.org/bundle.json",
  "spiffe_bundle_endpoint_profile": "https_web"
}
```
*Figure 1: A SPIFFE Trust Domain Configuration Document served at `https://example.org/.well-known/wimse-trust-domain`.*


# 7. Security Considerations

TODO