---
title: "Automatic Certificate Management Environment (ACME)"
abbrev: ACME
docname: draft-ietf-acme-acme-01
date: 2015-10-04
category: std
ipr: trust200902

stand_alone: yes
pi: [toc, sortrefs, symrefs]

author:
 -
    ins: R. Barnes
    name: Richard Barnes
    org: Mozilla
    email: rlb@ipv.sx
 -
    ins: J. Hoffman-Andrews
    name: Jacob Hoffman-Andrews
    org: EFF
    email: jsha@eff.org
 -
    ins: J. Kasten
    name: James Kasten
    org: University of Michigan
    email: jdkasten@umich.edu


normative:
  RFC2119:
  RFC2314:
  RFC2985:
  RFC2986:
  RFC3339:
  RFC3986:
  RFC4514:
  RFC4648:
  RFC5226:
  RFC5246:
  RFC5280:
  RFC5753:
  RFC5988:
  RFC6066:
  RFC6570:
  RFC6844:
  RFC6962:
  RFC7159:
  RFC7469:
  RFC7515:
  RFC7517:
  RFC7518:
  RFC7638:
  I-D.ietf-appsawg-http-problem:
  SEC1:
    target: http://www.secg.org/sec1-v2.pdf
    title: "SEC 1: Elliptic Curve Cryptography"
    author:
      organization: Standards for Efficient Cryptography Group
    date: 2009-05-01

informative:
  RFC2818:
  RFC3552:
  W3C.CR-cors-20130129:
  W3C.WD-capability-urls-20140218:
  I-D.vixie-dnsext-dns0x20:


--- abstract

Certificates in the Web's X.509 PKI (PKIX) are used for a number of purposes,
the most significant of which is the authentication of domain names.  Thus,
certificate authorities in the Web PKI are trusted to verify that an applicant
for a certificate legitimately represents the domain name(s) in the certificate.
Today, this verification is done through a collection of ad hoc mechanisms.
This document describes a protocol that a certificate authority (CA) and an
applicant can use to automate the process of verification and certificate
issuance.  The protocol also provides facilities for other certificate
management functions, such as certificate revocation.

DISCLAIMER: This is a WIP draft of ACME and has not yet had a thorough security
analysis.

RFC EDITOR: PLEASE REMOVE THE FOLLOWING PARAGRAPH: The source for this draft is
maintained in GitHub. Suggested changes should be submitted as pull requests at
<https://github.com/ietf-wg-acme/acme>. Instructions are on that page as well.
Editorial changes can be managed in GitHub, but any substantive change should be
discussed on the ACME mailing list (acme@ietf.org).

--- middle

# Introduction

Certificates in the Web PKI are most commonly used to authenticate domain names.
Thus, certificate authorities in the Web PKI are trusted to verify that an
applicant for a certificate legitimately represents the domain name(s) in the
certificate.

Existing Web PKI certificate authorities tend to run on a set of ad hoc
protocols for certificate issuance and identity verification.  A typical user
experience is something like:

* Generate a PKCS#10 {{RFC2314}} Certificate Signing Request (CSR).
* Cut-and-paste the CSR into a CA web page.
* Prove ownership of the domain by one of the following methods:
   * Put a CA-provided challenge at a specific place on the web server.
   * Put a CA-provided challenge at a DNS location corresponding to the target
     domain.
   * Receive CA challenge at a (hopefully) administrator-controlled e-mail
     address corresponding to the domain and then respond to it on the CA's web
     page.
* Download the issued certificate and install it on their Web Server.

With the exception of the CSR itself and the certificates that are issued, these
are all completely ad hoc procedures and are accomplished by getting the human
user to follow interactive natural-language instructions from the CA rather than
by machine-implemented published protocols.  In many cases, the instructions are
difficult to follow and cause significant confusion.  Informal usability tests
by the authors indicate that webmasters often need 1-3 hours to obtain and
install a certificate for a domain.  Even in the best case, the lack of
published, standardized mechanisms presents an obstacle to the wide deployment
of HTTPS and other PKIX-dependent systems because it inhibits mechanization of
tasks related to certificate issuance, deployment, and revocation.

This document describes an extensible framework for automating the issuance and
domain validation procedure, thereby allowing servers and infrastructural
software to obtain certificates without user interaction.  Use of this protocol
should radically simplify the deployment of HTTPS and the practicality of PKIX
authentication for other protocols based on TLS {{RFC5246}}.

# Deployment Model and Operator Experience

The major guiding use case for ACME is obtaining certificates for Web sites
(HTTPS {{RFC2818}}).  In that case, the server is intended to speak for one or
more domains, and the process of certificate issuance is intended to verify that
the server actually speaks for the domain(s).

Different types of certificates reflect different kinds of CA verification of
information about the certificate subject.  "Domain Validation" (DV)
certificates are by far the most common type.  For DV validation, the CA merely
verifies that the requester has effective control of the web server and/or DNS
server for the domain, but does not explicitly attempt to verify their
real-world identity.  (This is as opposed to "Organization Validation" (OV) and
"Extended Validation" (EV) certificates, where the process is intended to also
verify the real-world identity of the requester.)

DV certificate validation commonly checks claims about properties related to
control of a domain name -- properties that can be observed by the issuing
authority in an interactive process that can be conducted purely online.  That
means that under typical circumstances, all steps in the request, verification,
and issuance process can be represented and performed by Internet protocols with
no out-of-band human intervention.

When deploying a current HTTPS server, an operator generally gets a prompt to
generate a self-signed certificate.  When an operator deploys an ACME-compatible
web server, the experience would be something like this:

* The ACME client prompts the operator for the intended domain name(s) that the
  web server is to stand for.
* The ACME client presents the operator with a list of CAs from which it could
  get a certificate.  (This list will change over time based on the capabilities
  of CAs and updates to ACME configuration.) The ACME client might prompt the
  operator for payment information at this point.
* The operator selects a CA.
* In the background, the ACME client contacts the CA and requests that a
  certificate be issued for the intended domain name(s).
* Once the CA is satisfied, the certificate is issued and the ACME client
  automatically downloads and installs it, potentially notifying the operator
  via e-mail, SMS, etc.
* The ACME client periodically contacts the CA to get updated certificates,
  stapled OCSP responses, or whatever else would be required to keep the server
  functional and its credentials up-to-date.

The overall idea is that it's nearly as easy to deploy with a CA-issued
certificate as a self-signed certificate, and that once the operator has done
so, the process is self-sustaining with minimal manual intervention.  Close
integration of ACME with HTTPS servers, for example, can allow the immediate and
automated deployment of certificates as they are issued, optionally sparing the
human administrator from additional configuration work.


# Terminology

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL
NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
document are to be interpreted as described in RFC 2119 {{RFC2119}}.

The two main roles in ACME are “client” and “server”.  The ACME client uses the
protocol to request certificate management actions, such as issuance or
revocation.  An ACME client therefore typically runs on a web server, mail
server, or some other server system which requires valid TLS certificates.  The
ACME server runs at a certificate authority, and responds to client requests,
performing the requested actions if the client is authorized.

For simplicity, in all HTTPS transactions used by ACME, the ACME client is the
HTTPS client and the ACME server is the HTTPS server.

In the discussion below, we will refer to three different types of keys / key
pairs:

Subject Public Key:
: A public key to be included in a certificate.

Account Key Pair:
: A key pair for which the ACME server considers the holder of the private key
authorized to manage certificates for a given identifier.  The same key pair may
be authorized for multiple identifiers.

Recovery Key:
: A MAC key that a client can use to demonstrate that it participated in
a prior registration transaction.

ACME messaging is based on HTTPS {{RFC2818}} and JSON {{RFC7159}}.  Since JSON
is a text-based format, binary fields are Base64-encoded.  For Base64 encoding,
we use the variant defined in {{RFC7515}}.  The important features of this
encoding are (1) that it uses the URL-safe character set, and (2) that "="
padding characters are stripped.

Some HTTPS bodies in ACME are authenticated and integrity-protected by being
encapsulated in a JSON Web Signature (JWS) object {{RFC7515}}.  ACME uses a
profile of JWS, with the following restrictions:

* The JWS MUST use the Flattened JSON Serialization
* The JWS MUST be encoded using UTF-8
* The JWS Header or Protected Header MUST include "alg" and "jwk" fields
* The JWS MUST NOT have the value "none" in its "alg" field

Additionally, JWS objects used in ACME MUST include the "nonce" header
parameter, defined below.

# Protocol Overview

ACME allows a client to request certificate management actions using a set of
JSON messages carried over HTTPS.   In some ways, ACME functions much like a
traditional CA, in which a user creates an account, adds identifiers to that
account (proving control of the domains), and requests certificate issuance for
those domains while logged in to the account.

In ACME, the account is represented by an account key pair.  The "add a domain"
function is accomplished by authorizing the key pair for a given domain.
Certificate issuance and revocation are authorized by a signature with the key
pair.

The first phase of ACME is for the client to register with the ACME server.  The
client generates an asymmetric key pair and associates this key pair with a set
of contact information by signing the contact information.  The server
acknowledges the registration by replying with a registration object echoing the
client's input.

~~~~~~~~~~
      Client                                                  Server

      Contact Information
      Signature                     ------->

                                    <-------            Registration
~~~~~~~~~~

Before a client can issue certificates, it must establish an authorization with
the server for an account key pair to act for the identifier(s) that it wishes
to include in the certificate.  To do this, the client must demonstrate to the
server both (1) that it holds the private key of the account key pair, and (2)
that it has authority over the identifier being claimed.

Proof of possession of the account key is built into the ACME protocol.  All
messages from the client to the server are signed by the client, and the server
verifies them using the public key of the account key pair.

To verify that the client controls the identifier being claimed, the server
issues the client a set of challenges.  Because there are many different ways to
validate possession of different types of identifiers, the server will choose
from an extensible set of challenges that are appropriate for the identifier
being claimed.  The client responds with a set of responses that tell the server
which challenges the client has completed.  The server then validates the
challenges to check that the client has accomplished the challenge.

For example, if the client requests a domain name, the server might challenge
the client to provision a record in the DNS under that name, or to provision a
file on a web server referenced by an A or AAAA record under that name.  The
server would then query the DNS for the record in question, or send an HTTP
request for the file.  If the client provisioned the DNS or the web server as
expected, then the server considers the client authorized for the domain name.

~~~~~~~~~~
      Client                                                  Server

      Identifier
      Signature                     ------->

                                    <-------              Challenges

      Responses
      Signature                     ------->

                                    <-------       Updated Challenge

                          <~~~~~~~~Validation~~~~~~~~>

      Poll                          ------->

                                    <-------           Authorization
~~~~~~~~~~

Once the client has authorized an account key pair for an identifier, it can use
the key pair to authorize the issuance of certificates for the identifier.  To
do this, the client sends a PKCS#10 Certificate Signing Request (CSR) to the
  server (indicating the identifier(s) to be included in the issued certificate)
  and a signature over the CSR by the private key of the account key pair.

If the server agrees to issue the certificate, then it creates the certificate
and provides it in its response.  The certificate is assigned a URI, which the
client can use to fetch updated versions of the certificate.

~~~~~~~~~~
      Client                                                 Server

      CSR
      Signature                    -------->

                                   <--------            Certificate
~~~~~~~~~~

To revoke a certificate, the client simply sends a revocation request, signed
with an authorized key pair, and the server indicates whether the request has
succeeded.

~~~~~~~~~~
      Client                                                 Server

      Revocation request
      Signature                    -------->

                                   <--------                 Result
~~~~~~~~~~

Note that while ACME is defined with enough flexibility to handle different
types of identifiers in principle, the primary use case addressed by this
document is the case where domain names are used as identifiers.  For example,
all of the identifier validation challenges described in
{{identifier-validation-challenges}} below address validation of domain names.
The use of ACME for other protocols will require further specification, in order
to describe how these identifiers are encoded in the protocol, and what types of
validation challenges the server might require.

# Protocol Elements

This section describes several components that are used by ACME, and
general rules that apply to ACME transactions.

## HTTPS Requests

Each ACME function is accomplished by the client sending a sequence of
HTTPS requests to the server, carrying JSON messages.  Use of HTTPS is REQUIRED.
Clients SHOULD support HTTP public key pinning {{RFC7469}}, and servers SHOULD
emit pinning headers.  Each subsection of {{certificate-management}} below
describes the message formats used by the function, and the order in which
messages are sent.

All ACME requests with a non-empty body MUST encapsulate the body in a JWS
object, signed using the account key pair.  The server MUST verify the JWS
before processing the request.  (For readability, however, the examples below
omit this encapsulation.)  Encapsulating request bodies in JWS provides a simple
authentication of requests by way of key continuity.

Note that this implies that GET requests are not authenticated.  Servers MUST
NOT respond to GET requests for resources that might be considered sensitive.

An ACME request carries a JSON dictionary that provides the details of the
client's request to the server.  In order to avoid attacks that might arise from
sending a request object to a resource of the wrong type, each request object
MUST have a "resource" field that indicates what type of resource the request is
addressed to, as defined in the below table:

| Resource type        | "resource" value |
|:---------------------|:-----------------|
| New registration     | new-reg          |
| Recover registration | recover-reg      |
| New authorization    | new-authz        |
| New certificate      | new-cert         |
| Revoke certificate   | revoke-cert      |
| Registration         | reg              |
| Authorization        | authz            |
| Challenge            | challenge        |
| Certificate          | cert             |

Other fields in ACME request bodies are described below.

ACME servers that are intended to be generally accessible need to use
Cross-Origin Resource Sharing (CORS) in order to be accessible from
browser-based clients {{W3C.CR-cors-20130129}}.  Such servers SHOULD set the
Access-Control-Allow-Origin header field to the value "*".

## Registration Objects

An ACME registration resource represents a set of metadata associated to an
account key pair.  Registration resources have the following structure:

key (required, dictionary):
: The public key of the account key pair, encoded as a JSON Web Key object
{{RFC7517}}.

contact (optional, array of string):
: An array of URIs that the server can use to contact the client for issues
related to this authorization. For example, the server may wish to notify the
client about server-initiated revocation.

agreement (optional, string):
: A URI referring to a subscriber agreement or terms of service provided by the
server (see below).  Including this field indicates the client's agreement with
the referenced terms.

authorizations (optional, string):
: A URI from which a list of authorizations granted to this account can be
fetched via a GET request.  The result of the GET request MUST be a JSON object
whose "authorizations" field is an array of strings, where each string is the
URI of an authorization belonging to this registration.  The server SHOULD
include pending authorizations, and SHOULD NOT include authorizations that are
invalid or expired.

certificates (optional, string):
: A URI from which a list of certificates issued for this account can be fetched
via a GET request.  The result of the GET request MUST be a JSON object whose
"certificates" field is an array of strings, where each string is the URI of a
certificate.  The server SHOULD NOT include expired or revoked certificates.

~~~~~~~~~~
{
  "resource": "new-reg",
  "contact": [
    "mailto:cert-admin@example.com",
    "tel:+12025551212"
  ],
  "agreement": "https://example.com/acme/terms",
  "authorizations": "https://example.com/acme/reg/1/authz",
  "certificates": "https://example.com/acme/reg/1/cert",
}
~~~~~~~~~~

## Authorization Objects

An ACME authorization object represents server's authorization for an account to
represent an identifier.  In addition to the identifier, an authorization
includes several metadata fields, such as the status of the authorization (e.g.,
"pending", "valid", or "revoked") and which challenges were used to validate
possession of the identifier.

The structure of an ACME authorization resource is as follows:

identifier (required, dictionary of string):
: The identifier that the account is authorized to represent

  type (required, string):
  : The type of identifier.

  value (required, string):
  : The identifier itself.

status (optional, string):
: The status of this authorization.  Possible values are: "unknown", "pending",
"processing", "valid", "invalid" and "revoked".  If this field is missing, then
the default value is "pending".

expires (optional, string):
: The date after which the server will consider this
authorization invalid, encoded in the format specified in RFC 3339 {{RFC3339}}.

challenges (required, array):
: The challenges that the client needs to fulfill
in order to prove possession of the identifier (for pending authorizations).
For final authorizations, the challenges that were used.  Each array entry is a
dictionary with parameters required to validate the challenge, as specified in
{{identifier-validation-challenges}}.

combinations (optional, array of arrays of integers):
: A collection of sets of
challenges, each of which would be sufficient to prove possession of the
identifier. Clients complete a set of challenges that covers at least one
set in this array. Challenges are identified by their indices in the challenges
array.  If no "combinations" element is included in an authorization object, the
client completes all challenges.

The only type of identifier defined by this specification is a fully-qualified
domain name (type: "dns").  The value of the identifier MUST be the ASCII
representation of the domain name.  Wildcard domain names (with "*" as the first
label) MUST NOT be included in authorization requests.  See
{{certificate-issuance}} below for more information about wildcard domains.

~~~~~~~~~~
{
  "status": "valid",
  "expires": "2015-03-01",

  "identifier": {
    "type": "dns",
    "value": "example.org"
  },

  "challenges": [
    {
      "type": "http-01",
      "status": "valid",
      "validated": "2014-12-01T12:05Z",
      "keyAuthorization": "SXQe-2XODaDxNR...vb29HhjjLPSggwiE"
    }
  ],
}
~~~~~~~~~~


## Errors

Errors can be reported in ACME both at the HTTP layer and within ACME payloads.
ACME servers can return responses with an HTTP error response code (4XX or 5XX).
For example:  If the client submits a request using a method not allowed in this
document, then the server MAY return status code 405 (Method Not Allowed).

When the server responds with an error status, it SHOULD provide additional
information using problem document {{I-D.ietf-appsawg-http-problem}}.  The
"type" and "detail" fields MUST be populated.  To facilitate automatic response
to errors, this document defines the following standard tokens for use in the
"type" field (within the "urn:ietf:params:acme:error:" namespace):

| Code            | Semantic                                                 |
|:----------------|:---------------------------------------------------------|
| badCSR          | The CSR is unacceptable (e.g., due to a short key)       |
| badNonce        | The client sent an unacceptable anti-replay nonce        |
| connection      | The server could not connect to the client for DV        |
| dnssec          | The server could not validate a DNSSEC signed domain     |
| malformed       | The request message was malformed                        |
| serverInternal  | The server experienced an internal error                 |
| tls             | The server experienced a TLS error during DV             |
| unauthorized    | The client lacks sufficient authorization                |
| unknownHost     | The server could not resolve a domain name               |
| rateLimited     | The request exceeds a rate limit                         |

This list is not exhaustive. The server MAY return errors whose "type" field is
set to a URI other than those defined above.  Servers MUST NOT use the ACME URN
namespace for errors other than the standard types.  Clients SHOULD display the
"detail" field of such errors.

Authorization and challenge objects can also contain error information to
indicate why the server was unable to validate authorization.

TODO: Flesh out errors and syntax for them

## Replay protection

In order to protect ACME resources from any possible replay attacks, ACME
requests have a mandatory anti-replay mechanism.  This mechanism is based on the
server maintaining a list of nonces that it has issued to clients, and requiring
any signed request from the client to carry such a nonce.

An ACME server MUST include a Replay-Nonce header field in each successful
response it provides to a client, with contents as specified below.  In
particular, the ACME server MUST provide a Replay-Nonce header field in response
to a HEAD request for any valid resource.  (This allows clients to easily obtain
a fresh nonce.)  It MAY also provide nonces in error responses.

Every JWS sent by an ACME client MUST include, in its protected header, the
"nonce" header parameter, with contents as defined below.  As part of JWS
verification, the ACME server MUST verify that the value of the "nonce" header
is a value that the server previously provided in a Replay-Nonce header field.
Once a nonce value has appeared in an ACME request, the server MUST consider it
invalid, in the same way as a value it had never issued.

When a server rejects a request because its nonce value was unacceptable (or not
present), it SHOULD provide HTTP status code 400 (Bad Request), and indicate the
ACME error code "urn:acme:badNonce".

The precise method used to generate and track nonces is up to the server.  For
example, the server could generate a random 128-bit value for each response,
keep a list of issued nonces, and strike nonces from this list as
they are used.

### Replay-Nonce

The "Replay-Nonce" header field includes a server-generated value that the
server can use to detect unauthorized replay in future client requests.  The
server should generate the value provided in Replay-Nonce in such a way that
they are unique to each message, with high probability.

The value of the Replay-Nonce field MUST be an octet string encoded according to
the base64url encoding described in Section 2 of {{RFC7515}}.  Clients MUST
ignore invalid Replay-Nonce values.

~~~~~
  base64url = [A-Z] / [a-z] / [0-9] / "-" / "_"

  Replay-Nonce = *base64url
~~~~~

The Replay-Nonce header field SHOULD NOT be included in HTTP request messages.

### "nonce" (Nonce) JWS header parameter

The "nonce" header parameter provides a unique value that enables the verifier
of a JWS to recognize when replay has occurred. The "nonce" header parameter
MUST be carried in the protected header of the JWS.

The value of the "nonce" header parameter MUST be an octet string, encoded
according to the base64url encoding described in Section 2 of {{RFC7515}}.  If
the value of a "nonce" header parameter is not valid according to this encoding,
then the verifier MUST reject the JWS as malformed.

# Certificate Management

In this section, we describe the certificate management functions that ACME
enables:

  * Account Key Registration
  * Account Recovery
  * Account Key Authorization
  * Certificate Issuance
  * Certificate Renewal
  * Certificate Revocation

## Resources

ACME is structured as a REST application with a few types of resources:

* Registration resources, representing information about an account
* Authorization resources, representing an account's authorization to act for an
  identifier
* Challenge resources, representing a challenge to prove control of an
  identifier
* Certificate resources, representing issued certificates
* A "directory" resource
* A "new-registration" resource
* A "new-authorization" resource
* A "new-certificate" resource
* A "revoke-certificate" resource

For the "new-X" resources above, the server MUST have exactly one resource for
each function.  This resource may be addressed by multiple URIs, but all must
provide equivalent functionality.

In general, the intent is for authorization and certificate resources to contain
only public information, so that CAs may publish these resources to document
what certificates have been issued and how they were authorized.  Non-public
information, such as contact information, is stored in registration resources.

ACME uses different URIs for different management functions. Each function is
listed in a directory along with its corresponding URI, so clients only need to
be configured with the directory URI.

The "up" link relation is used with challenge resources to indicate the
authorization resource to which a challenge belongs.  It is also used from
certificate resources to indicate a resource from which the client may fetch a
chain of CA certificates that could be used to validate the certificate in the
original resource.

The "directory" link relation is present on all resources other than the
directory and indicates the directory URL.

The following diagram illustrates the relations between resources on an ACME
server.  The solid lines indicate link relations, and the dotted lines
correspond to relationships expressed in other ways, e.g., the Location header
in a 201 (Created) response.

~~~~~~~~~~
                               directory
                                   .
                                   .
       ....................................................
       .                  .                  .            .
       .                  .                  .            .
       V     "next"       V      "next"      V            V
    new-reg ---+----> new-authz ---+----> new-cert    revoke-cert
       .       |          .        |         .            ^
       .       |          .        |         .            | "revoke"
       V       |          V        |         V            |
      reg* ----+        authz -----+       cert-----------+
                         . ^                 |
                         . | "up"            | "up"
                         V |                 V
                       challenge         cert-chain
~~~~~~~~~~

The following table illustrates a typical sequence of requests required to
establish a new account with the server, prove control of an identifier, issue a
certificate, and fetch an updated certificate some time after issuance.  The
"->" is a mnemonic for a Location header pointing to a created resource.

| Action             | Request        | Response     |
|:-------------------|:---------------|:-------------|
| Register           | POST new-reg   | 201 -> reg   |
| Request challenges | POST new-authz | 201 -> authz |
| Answer challenges  | POST challenge | 200          |
| Poll for status    | GET  authz     | 200          |
| Request issuance   | POST new-cert  | 201 -> cert  |
| Check for new cert | GET  cert      | 200          |

The remainder of this section provides the details of how these resources are
structured and how the ACME protocol makes use of them.

## Directory

In order to help clients configure themselves with the right URIs for each ACME
operation, ACME servers provide a directory object. This should be the root URL
with which clients are configured. It is a JSON dictionary, whose keys are the
"resource" values listed in {{https-requests}}, and whose values are the
URIs used to accomplish the corresponding function.

The dictionary MAY additionally contain a key "meta". If present, it MUST be a
JSON dictionary; each item in the dictionary is an item of metadata relating to
the service provided by the ACME server.

The following metadata items are defined, all of which are OPTIONAL:

"terms-of-service":
: A string containing a URI identifying the current terms of service.

"website":
: String containing an HTTP or HTTPS URL locating a website providing more
information about the ACME server.

"caa-identities":
: If present, MUST be an array of strings. Each string MUST be a lowercase
hostname which the ACME server recognises as referring to itself for the
purposes of CAA record validation as defined in {{RFC6844}}.  This allows
clients to determine the correct issuer domain name to use when configuring CAA
record.

Clients access the directory by sending a GET request to the directory URI.

~~~~~~~~~~
HTTP/1.1 200 OK
Content-Type: application/json

{
  "new-reg": "https://example.com/acme/new-reg",
  "recover-reg": "https://example.com/acme/recover-reg",
  "new-authz": "https://example.com/acme/new-authz",
  "new-cert": "https://example.com/acme/new-cert",
  "revoke-cert": "https://example.com/acme/revoke-cert",
  "meta": {
    "terms-of-service": "https://example.com/acme/terms",
    "website": "https://www.example.com/",
    "caa-identities": ["example.com"]
  }
}
~~~~~~~~~~

## Registration

A client creates a new account with the server by sending a POST request to the
server's new-registration URI.  The body of the request is a stub registration
object containing only the "contact" field (along with the required "resource"
field).

~~~~~~~~~~
POST /acme/new-registration HTTP/1.1
Host: example.com

{
  "resource": "new-reg",
  "contact": [
    "mailto:cert-admin@example.com",
    "tel:+12025551212"
  ],
}
/* Signed as JWS */
~~~~~~~~~~

The server MUST ignore any values provided in the "key", "authorizations", and
"certificates" fields in registration bodies sent by the client, as well as any
other fields that it does not recognize.  If new fields are specified in the
future, the specification of those fields MUST describe whether they may be
provided by the client.

The server creates a registration object with the included contact information.
The "key" element of the registration is set to the public key used to verify
the JWS (i.e., the "jwk" element of the JWS header).  The server returns this
registration object in a 201 (Created) response, with the registration URI in a
Location header field.  The server MUST also indicate its new-authorization URI
using the "next" link relation.

If the server already has a registration object with the provided account key,
then it MUST return a 409 (Conflict) response and provide the URI of that
registration in a Location header field.  This allows a client that has an
account key but not the corresponding registration URI to recover the
registration URI.

If the server wishes to present the client with terms under which the ACME
service is to be used, it MUST indicate the URI where such terms can be accessed
in a Link header with link relation "terms-of-service".  As noted above, the
client may indicate its agreement with these terms by updating its registration
to include the "agreement" field, with the terms URI as its value.  When these
terms change in a way that requires an agreement update, the server MUST
use a different URI in the Link header.

~~~~~~~~~~
HTTP/1.1 201 Created
Content-Type: application/json
Location: https://example.com/acme/reg/asdf
Link: <https://example.com/acme/new-authz>;rel="next"
Link: <https://example.com/acme/recover-reg>;rel="recover"
Link: <https://example.com/acme/terms>;rel="terms-of-service"
Link: <https://example.com/acme/some-directory>;rel="directory"

{
  "key": { /* JWK from JWS header */ },

  "contact": [
    "mailto:cert-admin@example.com",
    "tel:+12025551212"
  ]
}
~~~~~~~~~~

If the client wishes to update this information in the future, it sends a POST
request with updated information to the registration URI.  The server MUST
ignore any updates to the "key", "authorizations, or "certificates" fields, and
MUST verify that the request is signed with the private key corresponding to the
"key" field of the request before updating the registration.

For example, to update the contact information in the above registration, the
client could send the following request:

~~~~~~~~~~
POST /acme/reg/asdf HTTP/1.1
Host: example.com

{
  "resource": "reg",
  "contact": [
    "mailto:certificates@example.com",
    "tel:+12125551212"
  ],
}
/* Signed as JWS */
~~~~~~~~~~

Servers SHOULD NOT respond to GET requests for registration resources as these
requests are not authenticated.  If a client wishes to query the server for
information about its account (e.g., to examine the "contact" or "certificates"
fields), then it SHOULD do so by sending a POST request with an empty update.
That is, it should send a JWS whose payload is trivial ({"resource":"reg"}).
In this case the server reply MUST contain the same link headers sent for a
new registration, to allow a client to retrieve the "new-authorization" and
"terms-of-service" URI

## Account Key Roll-over

A client may wish to change the public key that is associated with a
registration, e.g., in order to mitigate the risk of key compromise.  To do
this, the client first constructs a JSON object representing a request to
update the registration:

resource (required, string):
: The string "reg", indicating an update to the registration.

oldKey (required, string):
: The JWK thumbprint of the old key {{RFC7638}}, base64url-encoded

~~~~~~~~~~
{
  "resource": "reg",
  "oldKey": "D7J9RL1f-RWUl68JP-gW1KSl2TkIrJB7hK6rLFFeYMU"
}
~~~~~~~~~~

The client signs this object with the new key pair and encodes the object and
signature as a JWS.  The client then sends this JWS to the server in the
"newKey" field of a request to update the registration.

~~~~~~~~~~
POST /acme/reg/asdf HTTP/1.1
Host: example.com

{
  "resource": "reg",
  "newKey": /* JSON object signed as JWS with new key */
}
/* Signed as JWS with original key */
~~~~~~~~~~

On receiving a request to the registration URL with the "newKey" attribute set,
the server MUST perform the following steps:

1. Check that the contents of the "newKey" attribute are a valid JWS
2. Check that the "newKey" JWS verifies using the key in the "jwk" header
   parameter of the JWS
3. Check that the payload of the JWS is a valid JSON object
4. Check that the "resource" field of the object has the value "reg"
5. Check that the "oldKey" field of the object contains the JWK thumbprint of
   the account key for this registration

If all of these checks pass, then the server updates the registration by
replacing the old account key with the public key carried in the "jwk" header
parameter of the "newKey" JWS object.


## Account Recovery

Once a client has created an account with an ACME server, it is possible that
the private key for the account will be lost.  The recovery contacts included in
the registration allows the client to recover from this situation, as long as
it still has access to these contacts.

By "recovery", we mean that the information associated with an old account key
is bound to a new account key.  When a recovery process succeeds, the server
provides the client with a new registration whose contents are the same as base
registration object -- except for the "key" field, which is set to the new
account key.  The server reassigns resources associated with the base
registration to the new registration (e.g., authorizations and certificates).
The server SHOULD delete the old registration resource after it has been used as
a base for recovery.

In addition to the recovery mechanisms defined by ACME, individual client
implementations may also offer implementation-specific recovery mechanisms.  For
example, if a client creates account keys deterministically from a seed value,
then this seed could be used to recover the account key by re-generating it.  Or
an implementation could escrow an encrypted copy of the account key with a cloud
storage provider, and give the encryption key to the user as a recovery value.

The client requests recovery by asking that the server send a message to one
of the contact URIs registered for the account.  That message indicates some
action that the server requires the client's user to perform, e.g., clicking a
link in an email.  If the user successfully completes the server's required
actions, then the server will bind the account to the new account key.

(Note that this process is almost entirely out of band with respect to ACME.
ACME only allows the client to initiate the process, and the server to indicate
the result.)

To initiate recovery, the client sends a POST request to the
server's recover-registration URI, with a body specifying which registration is
to be recovered.  The body of the request MUST be signed by the client's new
account key pair.

method (required, string):
: The string "contact"

base (required, string):
: The URI for the registration to be recovered.

~~~~~~~~~~
POST /acme/recover-reg HTTP/1.1
Host: example.com

{
  "resource": "recover-reg",
  "method": "contact",
  "base": "https://example.com/acme/reg/asdf",
  "contact": [
    "mailto:forgetful@example.net"
  ]
}
/* Signed as JWS, with new account key */
~~~~~~~~~~

If the server agrees to attempt recovery, then it creates a new registration
resource containing a stub registration object.  The stub registration has the
client's new account key and contacts, but no authorizations or certificates
associated.  The server returns the stub contact in a 201 (Created) response,
along with a Location header field indicating the URI for the new registration
resource (which will be the registration URI if the recovery succeeds).

~~~~~~~~~~
HTTP/1.1 201 Created
Content-Type: application/json
Location: https://example.com/acme/reg/qwer

{
  "key": { /* new account key from JWS header */ },

  "contact": [
    "mailto:forgetful@example.net"
  ]
}
~~~~~~~~~~

After recovery has been initiated, the server follows its chosen recovery
process, out-of-band to ACME.  While the recovery process is ongoing, the client
may poll the registration resource's URI for status, by sending a POST request
with a trivial body ({"resource":"reg"}).  If the recovery process is still
pending, the server sends a 202 (Accepted) status code, and a Retry-After header
field. If the recovery process has failed, the server sends an error code (e.g.,
404), and SHOULD delete the stub registration resource.

If the recovery process has succeeded, then the server will send a 200 (OK)
response, containing the full registration object, with any necessary
information copied from the old registration).  The client may now use this in
the same way as if he had gotten it from a new-registration transaction.

## Identifier Authorization

The identifier authorization process establishes the authorization of an account
to manage certificates for a given identifier.  This process must assure the
server of two things: First, that the client controls the private key of the
account key pair, and second, that the client holds the identifier in question.
This process may be repeated to associate multiple identifiers to a key pair
(e.g., to request certificates with multiple identifiers), or to associate
multiple accounts with an identifier (e.g., to allow multiple entities to
manage certificates).

As illustrated by the figure in the overview section above, the authorization
process proceeds in two phases.  The client first requests a new authorization,
and the server issues challenges, then the client responds to those challenges
and the server validates the client's responses.

To begin the key authorization process, the client sends a POST request to the
server's new-authorization resource.  The body of the POST request MUST contain
a JWS object, whose payload is a partial authorization object.  This JWS object
MUST contain only the "identifier" field, so that the server knows what
identifier is being authorized.  The server MUST ignore any other fields present
in the client's request object.

The authorization object is implicitly tied to the account key used to sign the
request. Once created, the authorization may only be updated by that account.

~~~~~~~~~~
POST /acme/new-authorization HTTP/1.1
Host: example.com

{
  "resource": "new-authz",
  "identifier": {
    "type": "dns",
    "value": "example.org"
  }
}
/* Signed as JWS */
~~~~~~~~~~

Before processing the authorization further, the server SHOULD determine whether
it is willing to issue certificates for the identifier.  For example, the server
should check that the identifier is of a supported type.  Servers might also
check names against a blacklist of known high-value identifiers.  If the server
is unwilling to issue for the identifier, it SHOULD return a 403 (Forbidden)
error, with a problem document describing the reason for the rejection.

If the server is willing to proceed, it builds a pending authorization object
from the initial authorization object submitted by the client.

* "identifier" the identifier submitted by the client.
* "status": MUST be "pending"
* "challenges" and "combinations": As selected by the server's policy for this
  identifier
* The "expires" field MUST be absent.

The server allocates a new URI for this authorization, and returns a 201
(Created) response, with the authorization URI in a Location header field, and
the JSON authorization object in the body.

~~~~~~~~~~
HTTP/1.1 201 Created
Content-Type: application/json
Location: https://example.com/authz/asdf
Link: <https://example.com/acme/new-cert>;rel="next"
Link: <https://example.com/acme/some-directory>;rel="directory"

{
  "status": "pending",

  "identifier": {
    "type": "dns",
    "value": "example.org"
  },

  "challenges": [
    {
      "type": "http-01",
      "uri": "https://example.com/authz/asdf/0",
      "token": "IlirfxKKXAsHtmzK29Pj8A"
    },
    {
      "type": "dns-01",
      "uri": "https://example.com/authz/asdf/1",
      "token": "DGyRejmCefe7v4NfDGDKfA"
    }
  },

  "combinations": [[0], [1]]
}
~~~~~~~~~~

The client needs to respond with information to complete the challenges.  To do
this, the client updates the authorization object received from the server by
filling in any required information in the elements of the "challenges"
dictionary.  (This is also the stage where the client should perform any
actions required by the challenge.)

The client sends these updates back to the server in the form of a JSON object
with the response fields required by the challenge type, carried in a POST
request to the challenge URI (not authorization URI or the new-authorization
URI).  This allows the client to send information only for challenges it is
responding to.

For example, if the client were to respond to the "http-01" challenge in the
above authorization, it would send the following request:

~~~~~~~~~~
POST /acme/authz/asdf/0 HTTP/1.1
Host: example.com

{
  "resource": "challenge",
  "type": "http-01",
  "keyAuthorization": "IlirfxKKXA...vb29HhjjLPSggwiE"
}
/* Signed as JWS */
~~~~~~~~~~

The server updates the authorization document by updating its representation of
the challenge with the response fields provided by the client.  The server MUST
ignore any fields in the response object that are not specified as response
fields for this type of challenge.  The server provides a 200 (OK) response
with the updated challenge object as its body.

If the client's response is invalid for some reason, or does not provide the
server with appropriate information to validate the challenge, then the server
MUST return an HTTP error.  On receiving such an error, the client MUST undo any
actions that have been taken to fulfill the challenge, e.g., removing files that
have been provisioned to a web server.

Presumably, the client's responses provide the server with enough information to
validate one or more challenges.  The server is said to "finalize" the
authorization when it has completed all the validations it is going to complete,
and assigns the authorization a status of "valid" or "invalid", corresponding to
whether it considers the account authorized for the identifier.  If the final
state is "valid", the server MUST add an "expires" field to the authorization.
When finalizing an authorization, the server MAY remove the "combinations" field
(if present) or remove any challenges still pending.  The server SHOULD NOT
remove challenges with status "invalid".

Usually, the validation process will take some time, so the client will need to
poll the authorization resource to see when it is finalized.  For challenges
where the client can tell when the server has validated the challenge (e.g., by
seeing an HTTP or DNS request from the server), the client SHOULD NOT begin
polling until it has seen the validation request from the server.

To check on the status of an authorization, the client sends a GET request to
the authorization URI, and the server responds with the current  authorization
object. In responding to poll requests while the validation is still in
progress, the server MUST return a 202 (Accepted) response with a Retry-After
header field.

~~~~~~~~~~
GET /acme/authz/asdf HTTP/1.1
Host: example.com

HTTP/1.1 200 OK

{
  "status": "valid",
  "expires": "2015-03-01",

  "identifier": {
    "type": "dns",
    "value": "example.org"
  },

  "challenges": [
    {
      "type": "http-01"
      "status": "valid",
      "validated": "2014-12-01T12:05Z",
      "token": "IlirfxKKXAsHtmzK29Pj8A",
      "keyAuthorization": "IlirfxKKXA...vb29HhjjLPSggwiE"
    }
  ]
}
~~~~~~~~~~


## Certificate Issuance

The holder of an authorized key pair for an identifier may use ACME to request
that a certificate be issued for that identifier.  The client makes this request
by sending a POST request to the server's new-certificate resource.  The body of
the POST is a JWS object whose JSON payload contains a Certificate Signing
Request (CSR) {{RFC2986}}.  The CSR encodes the parameters of the requested
certificate; authority to issue is demonstrated by the JWS signature by an
account key, from which the server can look up related authorizations.

csr (required, string):
: A CSR encoding the parameters for the certificate being requested.  The CSR is
sent in the Base64url-encoded version of the DER format.  (Note: This field uses
the same modified Base64 encoding rules used elsewhere in this document, so it
is different from PEM.)

notBefore (optional, string):
: The requested value of the notBefore field in the certificate, in the date
format defined in {{RFC3339}}

notAfter (optional, string):
: The requested value of the notAfter field in the certificate, in the date
format defined in {{RFC3339}}

~~~~~~~~~~
POST /acme/new-cert HTTP/1.1
Host: example.com
Accept: application/pkix-cert

{
  "resource": "new-cert",
  "csr": "5jNudRx6Ye4HzKEqT5...FS6aKdZeGsysoCo4H9P",
  "notBefore": "2016-01-01T00:00:00Z",
  "notAfter": "2016-01-08T00:00:00Z"
}
/* Signed as JWS */
~~~~~~~~~~

The CSR encodes the client's requests with regard to the content of the
certificate to be issued.  The CSR MUST indicate the requested identifiers,
either in the commonName portion of the requested subject name, or in an
extensionRequest attribute {{RFC2985}} requesting a subjectAltName extension.

The values provided in the CSR are only a request, and are not guaranteed.  The
server or CA may alter any fields in the certificate before issuance.  For
example, the CA may remove identifiers that are not authorized for the account
key that signed the request.

It is up to the server's local policy to decide which names are acceptable in a
certificate, given the authorizations that the server associates with the
client's account key.  A server MAY consider a client authorized for a wildcard
domain if it is authorized for the underlying domain name (without the "*"
label).  Servers SHOULD NOT extend authorization across identifier types.  For
example, if a client is authorized for "example.com", then the server should not
allow the client to issue a certificate with an iPAddress subjectAltName, even
if it contains an IP address to which example.com resolves.

If the CA decides to issue a certificate, then the server creates a new
certificate resource and returns a URI for it in the Location header field of a
201 (Created) response.

~~~~~~~~~~
HTTP/1.1 201 Created
Location: https://example.com/acme/cert/asdf
~~~~~~~~~~

If the certificate is available at the time of the response, it is provided in
the body of the response.  If the CA has not yet issued the certificate, the
body of this response will be empty.  The client should then send a GET request
to the certificate URI to poll for the certificate.  As long as the certificate
is unavailable, the server MUST provide a 202 (Accepted) response and include a
Retry-After header to indicate when the server believes the certificate will be
issued (as in the example above).

~~~~~~~~~~
GET /acme/cert/asdf HTTP/1.1
Host: example.com
Accept: application/pkix-cert

HTTP/1.1 202 Accepted
Retry-After: 120
~~~~~~~~~~

The default format of the certificate is DER (application/pkix-cert).  The
client may request other formats by including an Accept header in its request.

The server provides metadata about the certificate in HTTP headers.  In
particular, the server MUST include a Link relation header field {{RFC5988}}
with relation "up" to provide a certificate under which this certificate was
issued, and one with relation "author" to indicate the registration under which
this certificate was issued.

The server MAY include an Expires header as a hint to the client about when to
renew the certificate.  (Of course, the real expiration of the certificate is
controlled by the notAfter time in the certificate itself.)

If the CA participates in Certificate Transparency (CT) {{RFC6962}}, then they
may want to provide the client with a Signed Certificate Timestamp (SCT) that
can be used to prove that a certificate was submitted to a CT log.  An SCT can
be included as an extension in the certificate or as an extension to OCSP
responses for the certificate.  The server can also provide the client with
direct access to an SCT for a certificate using a Link relation header field
with relation "ct-sct".

~~~~~~~~~~
GET /acme/cert/asdf HTTP/1.1
Host: example.com
Accept: application/pkix-cert

HTTP/1.1 200 OK
Content-Type: application/pkix-cert
Link: <https://example.com/acme/ca-cert>;rel="up";title="issuer"
Link: <https://example.com/acme/revoke-cert>;rel="revoke"
Link: <https://example.com/acme/reg/asdf>;rel="author"
Link: <https://example.com/acme/sct/asdf>;rel="ct-sct"
Link: <https://example.com/acme/some-directory>;rel="directory"
Location: https://example.com/acme/cert/asdf
Content-Location: https://example.com/acme/cert-seq/12345

[DER-encoded certificate]
~~~~~~~~~~

A certificate resource always represents the most recent certificate issued for
the name/key binding expressed in the CSR.  If the CA allows a certificate to be
renewed, then it publishes renewed versions of the certificate through the same
certificate URI.

Clients retrieve renewed versions of the certificate using a GET query to the
certificate URI, which the server should then return in a 200 (OK) response.
The server SHOULD provide a stable URI for each specific certificate in the
Content-Location header field, as shown above.  Requests to stable certificate
URIs MUST always result in the same certificate.

To avoid unnecessary renewals, the CA may choose not to issue a renewed
certificate until it receives such a request (if it even allows renewal at all).
In such cases, if the CA requires some time to generate the new certificate, the
CA MUST return a 202 (Accepted) response, with a Retry-After header field that
indicates when the new certificate will be available.  The CA MAY include the
current (non-renewed) certificate as the body of the response.

Likewise, in order to prevent unnecessary renewal due to queries by parties
other than the account key holder, certificate URIs should be structured as
capability URLs {{W3C.WD-capability-urls-20140218}}.

From the client's perspective, there is no difference between a certificate URI
that allows renewal and one that does not.  If the client wishes to obtain a
renewed certificate, and a GET request to the certificate URI does not yield
one, then the client may initiate a new-certificate transaction to request one.

## Certificate Revocation

To request that a certificate be revoked, the client sends a POST request to
the ACME server's revoke-cert URI.  The body of the POST is a JWS object whose
JSON payload contains the certificate to be revoked:

certificate (required, string):
: The certificate to be revoked, in the Base64url-encoded version of the DER
format.  (Note: This field uses the same modified Base64 encoding rules used
elsewhere in this document, so it is different from PEM.)

~~~~~~~~~~
POST /acme/revoke-cert HTTP/1.1
Host: example.com

{
  "resource": "revoke-cert",
  "certificate": "MIIEDTCCAvegAwIBAgIRAP8..."
}
/* Signed as JWS */
~~~~~~~~~~

Revocation requests are different from other ACME request in that they can be
signed either with an account key pair or the key pair in the certificate.
Before revoking a certificate, the server MUST verify at least one of these
conditions applies:

* the public key of the key pair signing the request matches the public key in
  the certificate.

* the key pair signing the request is an account key, and the corresponding
  account is authorized to act for all of the identifier(s) in the certificate.

If the revocation succeeds, the server responds with status code 200 (OK).  If
the revocation fails, the server returns an error.

~~~~~~~~~~
HTTP/1.1 200 OK
Content-Length: 0

--- or ---

HTTP/1.1 403 Forbidden
Content-Type: application/problem+json
Content-Language: en

{
  "type": "urn:acme:error:unauthorized"
  "detail": "No authorization provided for name example.net"
  "instance": "http://example.com/doc/unauthorized"
}
~~~~~~~~~~


# Identifier Validation Challenges

There are few types of identifiers in the world for which there is a standardized
mechanism to prove possession of a given identifier.  In all practical cases,
CAs rely on a variety of means to test whether an entity applying for a
certificate with a given identifier actually controls that identifier.

Challenges provide the server with assurance that an account key holder is also
the entity that controls an identifier.  For each type of challenge, it must be
the case that in order for an entity to successfully complete the challenge the
entity must both:

* Hold the private key of the account key pair used to respond to the challenge
* Control the identifier in question

{{security-considerations}} documents how the challenges defined in this
document meet these requirements.  New challenges will need to document how they
do.

To accommodate this reality, ACME includes an extensible challenge/response
framework for identifier validation.  This section describes an initial set of
Challenge types.  Each challenge must describe:

* Content of Challenge payloads (in Challenge messages)
* Content of Response payloads (in authorizationRequest messages)
* How the server uses the Challenge and Response to verify control of an
  identifier

The general structure of Challenge and Response payloads is as follows:

type (required, string):
: The type of Challenge or Response encoded in the object.

uri (required, string):
: The URI to which a response can be posted.

status (optional, string): : The status of this authorization.  Possible values
are: "unknown", "pending", "processing", "valid", "invalid" and "revoked".  If
this field is missing, then the default value is "pending".

validated (optional, string): : The time at which this challenge was completed
by the server, encoded in the format specified in RFC 3339 {{RFC3339}}.

error (optional, dictionary of string): : The error that occurred while the
server was validating the challenge, if any.  This field is structured as a
problem document {{I-D.ietf-appsawg-http-problem}}.

All additional fields are specified by the Challenge type.  The server MUST
ignore any values provided in the "uri", "status", "validated", and "error"
fields of a Response payload.  If the server sets a Challenge's "status" to
"invalid", it SHOULD also include the "error" field to help the client diagnose
why they failed the challenge.

Different challenges allow the server to obtain proof of different aspects of
control over an identifier.  In some challenges, like HTTP and TLS SNI, the
client directly proves its ability to do certain things related to the
identifier.  In the Proof of Possession challenge, the client proves historical
control of the identifier, by reference to a prior authorization transaction or
certificate.

The choice of which Challenges to offer to a client under which circumstances is
a matter of server policy.  A CA may choose different sets of challenges
depending on whether it has interacted with a domain before, and how.  For
example:

* New domain with no known certificates: Domain Validation (HTTP or TLS SNI)
* Domain for which known certs exist from other CAs: DV + Proof of Possession of
  previous CA-signed key
* Domain with a cert from this CA, lost account key: DV + PoP of ACME-certified
  Subject key
* Domain with a cert from this CA, all keys and recovery mechanisms lost: Out of
  band proof of authority for the domain

The identifier validation challenges described in this section all relate to
validation of domain names.  If ACME is extended in the future to support other
types of identifier, there will need to be new Challenge types, and they will
need to specify which types of identifier they apply to.

[[ Editor's Note: In pre-RFC versions of this specification, challenges are
labeled by type, and with the version of the draft in which they were
introduced.  For example, if an HTTP challenge were introduced in version -03
and a breaking change made in version -05, then there would be a challenge
labeled "http-03" and one labeled "http-05" -- but not one labeled "http-04",
since challenge in version -04 was compatible with one in version -04. ]]

[[ Editor's Note: Operators SHOULD NOT issue "combinations" arrays in
authorization objects that require the client to perform multiple challenges
over the same type, e.g., ["http-03", "http-05"].  Challenges within a type are
testing the same capability of the domain owner, and it may not be possible to
satisfy both at once. ]]

## Key Authorizations

Several of the challenges in this document makes use of a key authorization
string.  A key authorization expresses a domain holder's authorization for a
specified key to satisfy a specified challenge, by concatenating the token
for the challenge with a key fingerprint, separated by a "." character:

~~~~~~~~~~
key-authz = token || '.' || base64url(JWK_Thumbprint(accountKey))
~~~~~~~~~~

The "JWK_Thumbprint" step indicates the computation specified in {{RFC7638}},
using the SHA-256 digest.  As specified in the individual challenges below, the
token for a challenge is a JSON string comprised entirely of characters in the
URL-safe Base64 alphabet.  The "||" operator indicates concatenation of strings.

In computations involving key authorizations, such as the digest computations
required for the DNS and TLS SNI challenges, the key authorization string MUST
be represented in UTF-8 form (or, equivalently, ASCII).

An example of how to compute a JWK thumbprint can be found in Section 3.1 of
{{RFC7638}}.  Note that some cryptographic libraries prepend a zero octet to the
representation of the RSA public key parameters N and E, in order to avoid
ambiguity with regard to the sign of the number.  As noted in JWA {{RFC7518}}, a
JWK object MUST NOT include this zero octet.  That is, any initial zero octets
MUST be stripped before the values are Base64url-encoded.

## HTTP

With HTTP validation, the client in an ACME transaction proves its
control over a domain name by proving that it can provision resources on an HTTP
server that responds for that domain name.  The ACME server challenges the
client to provision a file with a specific JWS as its contents.

As a domain may resolve to multiple IPv4 and IPv6 addresses, the server will
connect to at least one of the hosts found in A and AAAA records, at its
discretion.  Because many webservers allocate a default HTTPS virtual host to a
particular low-privilege tenant user in a subtle and non-intuitive manner, the
challenge must be completed over HTTP, not HTTPS.

type (required, string):
: The string "http-01"

token (required, string):
: A random value that uniquely identifies the challenge.  This value MUST have
at least 128 bits of entropy, in order to prevent an attacker from guessing it.
It MUST NOT contain any characters outside the URL-safe Base64 alphabet.

~~~~~~~~~~
{
  "type": "http-01",
  "token": "evaGxfADs6pSRb2LAv9IZf17Dt3juxGJ-PCt92wr-oA",
}
~~~~~~~~~~

A client responds to this challenge by constructing a key authorization from
the "token" value provided in the challenge and the client's account key.  The
client then provisions the key authorization as a resource on the HTTP server
for the domain in question.

~~~~~~~~~~
evaGxfADs6pSRb2LAv9IZf17Dt3juxGJ-PCt92wr-oA
.nP1qzpXGymHBrUEepNY9HCsQk7K8KhOypzEt62jcerQ
~~~~~~~~~~

The path at which the resource is provisioned is comprised of the fixed prefix
".well-known/acme-challenge/", followed by the "token" value in the challenge.
The value of the resource MUST be the ASCII representation of the key
authorization.

~~~~~~~~~~
.well-known/acme-challenge/evaGxfADs6pSRb2LAv9IZf17Dt3juxGJ-PCt92wr-oA
~~~~~~~~~~

The client's response to this challenge indicates its agreement to this
challenge by sending the server the key authorization covering the challenge's
token and the client's account key:

keyAuthorization (required, string):
: The key authorization for this challenge.  This value MUST match the token
from the challenge and the client's account key.

~~~~~~~~~~
{
  "keyAuthorization": "evaGxfADs...62jcerQ"
}
/* Signed as JWS */
~~~~~~~~~~

On receiving a response, the server MUST verify that the key authorization in
the response matches the "token" value in the challenge and the client's account
key.  If they do not match, then the server MUST return an HTTP error in
response to the POST request in which the client sent the challenge.

Given a Challenge/Response pair, the server verifies the client's control of the
domain by verifying that the resource was provisioned as expected.

1. Form a URI by populating the URI template {{RFC6570}}
   "http://{domain}/.well-known/acme-challenge/{token}", where:
  * the domain field is set to the domain name being verified; and
  * the token field is set to the token in the challenge.
2. Verify that the resulting URI is well-formed.
3. Dereference the URI using an HTTP GET request.
4. Verify that the body of the response is well-formed key authorization.  The
   server SHOULD ignore whitespace characters at the end of the body.
5. Verify that key authorization provided by the server matches the token for
   this challenge and the client's account key.

If all of the above verifications succeed, then the validation is successful.
If the request fails, or the body does not pass these checks, then it has
failed.

## TLS with Server Name Indication (TLS SNI)

The TLS with Server Name Indication (TLS SNI) validation method
proves control over a domain name by requiring the client to configure a TLS
server referenced by an A/AAAA record under the domain name to respond to
specific connection attempts utilizing the Server Name Indication extension
{{RFC6066}}. The server verifies the client's challenge by accessing the
reconfigured server and verifying a particular challenge certificate is
presented.

type (required, string):
: The string "tls-sni-01"

token (required, string):
: A random value that uniquely identifies the challenge.  This value MUST have
at least 128 bits of entropy, in order to prevent an attacker from guessing it.
It MUST NOT contain any characters outside the URL-safe Base64 alphabet.

~~~~~~~~~~
{
  "type": "tls-sni-01",
  "token": "evaGxfADs6pSRb2LAv9IZf17Dt3juxGJ-PCt92wr-oA"
}
~~~~~~~~~~

A client responds to this challenge by constructing a key authorization from
the "token" value provided in the challenge and the client's account key.  The
client computes the SHA-256 digest Z of the UTF8-encoded key
authorization, and encodes Z in UTF-8 lower-case hexadecimal form.

The client generates a self-signed certificate for with a
single subjectAlternativeName extension dNSName that is
"\<Z[0:32]\>.\<Z[32:64]\>.acme.invalid", where "Z[0:32]" and "Z[32:64]"
represent the first 32 and last 32 characters of the hex-encoded value,
respectively (following the notation used in Python).  The client then
configures the TLS server at the domain such that when a handshake is initiated
with the Server Name Indication extension set to
"\<Z[0:32]\>.\<Z[32:64]\>.acme.invalid", the corresponding generated
certificate is presented.

The response to the TLS SNI challenge simply acknowledges that the client is ready
to fulfill this challenge.

keyAuthorization (required, string):
: The key authorization for this challenge.  This value MUST match the token
from the challenge and the client's account key.

~~~~~~~~~~
{
  "keyAuthorization": "evaGxfADs...62jcerQ",
}
/* Signed as JWS */
~~~~~~~~~~

On receiving a response, the server MUST verify that the key authorization in
the response matches the "token" value in the challenge and the client's account
key.  If they do not match, then the server MUST return an HTTP error in
response to the POST request in which the client sent the challenge.

Given a Challenge/Response pair, the ACME server verifies the client's control
of the domain by verifying that the TLS server was configured appropriately,
using these steps:

1. Compute the Z-value from the key authorization in the same way as the client.
2. Open a TLS connection to the domain name being validated on the requested
   port, presenting the value "\<Z[0:32]\>.\<Z[32:64]\>.acme.invalid" in the
   SNI field (where the comparison is case-insensitive).
3. Verify that the certificate contains a subjectAltName extension with the
   dNSName of "\<Z[0:32]\>.\<Z[32:64]\>.acme.invalid", and that no other dNSName
   entries of the form "*.acme.invalid" are present in the subjectAltName
   extension.

It is RECOMMENDED that the ACME server validation TLS connections from multiple
vantage points to reduce the risk of DNS hijacking attacks.

If all of the above verifications succeed, then the validation is successful.
Otherwise, the validation fails.

## Proof of Possession of a Prior Key

The Proof of Possession challenge verifies that a client possesses a private key
corresponding to a server-specified public key, as demonstrated by its ability
to sign with that key.  This challenge is meant to be used when the server knows
of a public key that is already associated with the identifier being claimed,
and wishes for new authorizations to be authorized by the holder of the
corresponding private key.  For DNS identifiers, for example, this can help
guard against domain hijacking.

This method is useful if a server policy calls for issuing a certificate only to
an entity that already possesses the subject private key of a particular prior
related certificate (perhaps issued by a different CA).  It may also help enable
other kinds of server policy that are related to authenticating a client's
identity using digital signatures.

This challenge proceeds in much the same way as the proof of possession of the
authorized key pair in the main ACME flow (challenge + authorizationRequest).
The server provides a nonce and the client signs over the nonce.  The main
difference is that rather than signing with the private key of the key pair
being authorized, the client signs with a private key specified by the server.
The server can specify which key pair(s) are acceptable directly (by indicating
a public key), or by asking for the key corresponding to a certificate.

The server provides the following fields as part of the challenge:

type (required, string):
: The string "proof-of-possession-01"

certs (optional, array of string):
: An array of certificates, in Base64url-encoded DER format, that contain
acceptable public keys.


~~~~~~~~~~
{
  "type": "proof-of-possession-01",
  "certs": ["MIIF7z...bYVQLY"]
}
~~~~~~~~~~

In response to this challenge, the client uses the private key corresponding to
one of the acceptable public keys to sign a JWS object including data related to
the challenge.  The validation object covered by the signature has the following
fields:

type (required, string):
: The string "proof-of-possession"

identifiers (required, identifier):
: A list of identifiers for which the holder of the prior key authorizes the new key

accountKey (required, JWK):
: The client's account public key

~~~~~~~~~~
{
  "type": "proof-of-possession-01",
  "identifiers: [{"type": "dns", "value": "example.com"}],
  "accountKey": { "kty": "RSA", ... }
}
~~~~~~~~~~

This JWS is NOT REQUIRED to have a "nonce" header parameter (as with the JWS
objects that carry ACME request objects).  This allows proof-of-possession
response objects to be computed off-line.  For example, as part of a domain
transfer, the new domain owner might require the old domain owner to sign a
proof-of-possession validation object, so that the new domain owner can present
that in an ACME transaction later.

The validation JWS MUST contain a "jwk" header parameter indicating the public
key under which the server should verify the JWS.

The client's response includes the server-provided nonce, together with a
signature over that nonce by one of the private keys requested by the server.

type (required, string):
: The string "proof-of-possession"

authorization (required, JWS):
: The validation JWS

~~~~~~~~~~
{
  "type": "proof-of-possession-01",
  "authorization": {
    "header": {
      "alg": "RS256",
      "jwk": {
        "kty": "RSA",
        "e": "AQAB",
        "n": "AMswMT...3aVtjE"
      }
    },
    "payload": "SfiR1...gSAl7A",
    "signature": "XcQLfL...cW5beg"
  }
}
~~~~~~~~~~

To validate a proof-of-possession challenge, the server performs the following
steps:

1. Verify that the public key in the "jwk" header of the "authorization" JWS
   corresponds to one of the certificates in the "certs" field of the challenge
2. Verify the "authorization" JWS using the key indicated in its "jwk" header
3. Decode the payload of the JWS as UTF-8 encoded JSON
4. Verify that there are exactly three fields in the decoded object, and that:
  * The "type" field is set to "proof-of-possession"
  * The "identifier" field contains the identifier for which authorization is
    being validated
  * The "accountKey" field matches the account key for which the challenge was
    issued

If all of the above verifications succeed, then the validation is successful.
Otherwise, the validation fails.

## DNS

When the identifier being validated is a domain name, the client can prove
control of that domain by provisioning resource records under it.   The DNS
challenge requires the client to provision a TXT record containing a designated
value under a specific validation domain name.

type (required, string):
: The string "dns-01"

token (required, string):
: A random value that uniquely identifies the challenge.  This value MUST have
at least 128 bits of entropy, in order to prevent an attacker from guessing it.
It MUST NOT contain any characters outside the URL-safe Base64 alphabet.

~~~~~~~~~~
{
  "type": "dns-01",
  "token": "evaGxfADs6pSRb2LAv9IZf17Dt3juxGJ-PCt92wr-oA"
}
~~~~~~~~~~

A client responds to this challenge by constructing a key authorization from the
"token" value provided in the challenge and the client's account key.  The
client then computes the SHA-256 digest of the key authorization.

The record provisioned to the DNS is the base64url encoding of this digest.  The
client constructs the validation domain name by prepending the label
"_acme-challenge" to the domain name being validated, then provisions a TXT
record with the digest value under that name. For example, if the domain name
being validated is "example.com", then the client would provision the following
DNS record:

~~~~~~~~~~
_acme-challenge.example.com. 300 IN TXT "gfj9Xq...Rg85nM"
~~~~~~~~~~

The response to the DNS challenge simply acknowledges that the client is ready
to fulfill this challenge.

keyAuthorization (required, string):
: The key authorization for this challenge.  This value MUST match the token
from the challenge and the client's account key.

~~~~~~~~~~
{
  "keyAuthorization": "evaGxfADs...62jcerQ",
}
/* Signed as JWS */
~~~~~~~~~~

On receiving a response, the server MUST verify that the key authorization in
the response matches the "token" value in the challenge and the client's account
key.  If they do not match, then the server MUST return an HTTP error in
response to the POST request in which the client sent the challenge.

To validate a DNS challenge, the server performs the following steps:

1. Compute the SHA-256 digest of the key authorization
2. Query for TXT records under the validation domain name
3. Verify that the contents of one of the TXT records matches the digest value

If all of the above verifications succeed, then the validation is successful.
If no DNS record is found, or DNS record and response payload do not pass these
checks, then the validation fails.

# IANA Considerations

TODO

* Register .well-known path
* Register Replay-Nonce HTTP header
* Register "nonce" JWS header parameter
* Register "urn:acme" namespace
* Create identifier validation method registry
* Registries of syntax tokens, e.g., message types / error types?

# Security Considerations

ACME is a protocol for managing certificates that attest to identifier/key
bindings.  Thus the foremost security goal of ACME is to ensure the integrity of
this process, i.e., to ensure that the bindings attested by certificates are
correct, and that only authorized entities can manage certificates.  ACME
identifies clients by their account keys, so this overall goal breaks down into
two more precise goals:

1. Only an entity that controls an identifier can get an account key authorized
   for that identifier
2. Once authorized, an account key's authorizations cannot be improperly
   transferred to another account key

In this section, we discuss the threat model that underlies ACME and the ways
that ACME achieves these security goals within that threat model.  We also
discuss the denial-of-service risks that ACME servers face, and a few other
miscellaneous considerations.

## Threat model

As a service on the Internet, ACME broadly exists within the Internet threat
model {{RFC3552}}.  In analyzing ACME, it is useful to think of an ACME server
interacting with other Internet hosts along three "channels":

* An ACME channel, over which the ACME HTTPS requests are exchanged
* A validation channel, over which the ACME server performs additional requests
  to validate a client's control of an identifier
* A contact channel, over which the ACME server sends messages to the registered
  contacts for ACME clients

~~~~~~~~~~
+------------+
|    ACME    |     ACME Channel
|   Client   |--------------------+
+------------+                    |
       ^                          V
       |   Contact Channel  +------------+
       +--------------------|    ACME    |
                            |   Server   |
                            +------------+
+------------+                    |
| Validation |<-------------------+
|   Server   |  Validation Channel
+------------+
~~~~~~~~~~

In practice, the risks to these channels are not entirely separate, but they are
different in most cases.  Each of the three channels, for example, uses a
different communications pattern: the ACME channel will comprise inbound HTTPS
connections to the ACME server, the validation channel outbound HTTP or DNS
requests, and the contact channel will use channels such as email and PSTN.

Broadly speaking, ACME aims to be secure against active and passive attackers on
any individual channel.  Some vulnerabilities arise (noted below), when an
attacker can exploit both the ACME channel and one of the others.

On the ACME channel, in addition to network-layer attackers, we also need to
account for application-layer man in the middle attacks, and for abusive use of
the protocol itself.  Protection against application-layer MitM addresses
potential attackers such as Content Distribution Networks (CDNs) and middleboxes
with a TLS MitM function.  Preventing abusive use of ACME means ensuring that an
attacker with access to the validation or contact channels can't obtain
illegitimate authorization by acting as an ACME client (legitimately, in terms
of the protocol).

## Integrity of Authorizations

ACME allows anyone to request challenges for an identifier by registering an
account key and sending a new-authorization request under that account key.  The
integrity of the authorization process thus depends on the identifier validation
challenges to ensure that the challenge can only be completed by someone who
both (1) holds the private key of the account key pair, and (2) controls the
identifier in question.

Validation responses need to be bound to an account key pair in order to avoid
situations where an ACME MitM can switch out a legitimate domain holder's
account key for one of his choosing, e.g.:

* Legitimate domain holder registers account key pair A
* MitM registers account key pair B
* Legitimate domain holder sends a new-authorization request signed under
  account key A
* MitM suppresses the legitimate request, but sends the same request signed
  under account key B
* ACME server issues challenges and MitM forwards them to the legitimate domain
  holder
* Legitimate domain holder provisions the validation response
* ACME server performs validation query and sees the response provisioned by the
  legitimate domain holder
* Because the challenges were issued in response to a message signed account key
  B, the ACME server grants authorization to account key B (the MitM) instead of
  account key A (the legitimate domain holder)

All of the challenges above that require an out-of-band query by the server have
a binding to the account private key, such that only the account private key
holder can successfully respond to the validation query:

* HTTP: The value provided in the validation request is signed by the
  account private key.
* TLS SNI: The validation TLS request uses the account key pair as the server's
  key pair.
* DNS: The MAC covers the account key, and the MAC key is derived from an ECDH
  public key signed with the account private key.
* Proof of possession of a prior key: The signature by the prior key covers the
  account public key.

The association of challenges to identifiers is typically done by requiring the
client to perform some action that only someone who effectively controls the
identifier can perform.  For the challenges in this document, the actions are:

* HTTP: Provision files under .well-known on a web server for the domain
* TLS SNI: Configure a TLS server for the domain
* DNS: Provision DNS resource records for the domain
* Proof of possession of a prior key: Sign using the private key specified by
  the server

There are several ways that these assumptions can be violated, both by
misconfiguration and by attack.  For example, on a web server that allows
non-administrative users to write to .well-known, any user can claim to own the
server's hostname by responding to an HTTP challenge, and likewise for TLS
configuration and TLS SNI.

The use of hosting providers is a particular risk for ACME validation.  If the
owner of the domain has outsourced operation of DNS or web services to a hosting
provider, there is nothing that can be done against tampering by the hosting
provider.  As far as the outside world is concerned, the zone or web site
provided by the hosting provider is the real thing.

More limited forms of delegation can also lead to an unintended party gaining
the ability to successfully complete a validation transaction.  For example,
suppose an ACME server follows HTTP redirects in HTTP validation and a
web site operator provisions a catch-all redirect rule that redirects requests
for unknown resources to different domain.  Then the target of the redirect
could use that to get a certificate through HTTP validation, since the
validation path will not be known to the primary server.

The DNS is a common point of vulnerability for all of these challenges.  An
entity that can provision false DNS records for a domain can attack the DNS
challenge directly, and can provision false A/AAAA records to direct the ACME
server to send its TLS SNI or HTTP validation query to a server of the
attacker's choosing.  There are a few different mitigations that ACME servers
can apply:

* Checking the DNSSEC status of DNS records used in ACME validation (for zones
  that are DNSSEC-enabled)
* Querying the DNS from multiple vantage points to address local attackers
* Applying mitigations against DNS off-path attackers, e.g., adding entropy to
  requests {{I-D.vixie-dnsext-dns0x20}} or only using TCP

Given these considerations, the ACME validation process makes it impossible for
any attacker on the ACME channel, or a passive attacker on the validation
channel to hijack the authorization process to authorize a key of the attacker's
choice.

An attacker that can only see the ACME channel would need to convince the
validation server to provide a response that would authorize the attacker's
account key, but this is prevented by binding the validation response to the
account key used to request challenges.  A passive attacker on the validation
channel can observe the correct validation response and even replay it, but that
response can only be used with the account key for which it was generated.

An active attacker on the validation channel can subvert the ACME process, by
performing normal ACME transactions and providing a validation response for his
own account key.  The risks due to hosting providers noted above are a
particular case.  For identifiers where the server already has some credential
associated with the domain this attack can be prevented by requiring the client
to complete a proof-of-possession challenge.

## Preventing Authorization Hijacking

The account recovery processes described in {{account-recovery}} allow
authorization to be transferred from one account key to another, in case the
former account key pair's private key is lost.  ACME needs to prevent these
processes from being exploited by an attacker to hijack the authorizations
attached to one key and assign them to a key of the attacker's choosing.

Recovery takes place in two steps:
1. Provisioning recovery information (contact or recovery key)
2. Using recovery information to recover an account

The provisioning process needs to ensure that only the account key holder ends
up with information that is useful for recovery.  The recovery process needs to
assure that only the (now former) account key holder can successfully execute
recovery, i.e., that this entity is the only one that can choose the new account
key that receives the capabilities held by the account being recovered.

Account recovery uses both the ACME channel and the contact channel.  The
provisioning process is only visible to an ACME MitM, and even then, the MitM
can only observe the contact information provided.  If the ACME attacker does
not also have access to the contact channel, there is no risk.

The security of the recovery process is entirely dependent on the security of
the contact channel.  The details of this will depend on the specific
out-of-band technique used by the server.  For example:

* If the server requires a user to click a link in a message sent to a contact
  address, then the contact channel will need to ensure that the message is only
  available to the legitimate owner of the contact address.  Otherwise, a
  passive attacker could see the link and click it first, or an active attacker
  could redirect the message.
* If the server requires a user to respond to a message sent to a contact
  address containing a secret value, then the contact channel will need to
  ensure that an attacker cannot observe the secret value and spoof a message
  from the contact address.

In practice, many contact channels that can be used to reach many clients do not
provide strong assurances of the types noted above.  In designing and deploying
recovery schemes, ACME servers operators will need to find an appropriate
balance between using contact channels that can reach many clients and using
contact-based recovery schemes that achieve an appropriate level of risk using
those contact channels.

## Denial-of-Service Considerations

As a protocol run over HTTPS, standard considerations for TCP-based and
HTTP-based DoS mitigation also apply to ACME.

At the application layer, ACME requires the server to perform a few potentially
expensive operations.  Identifier validation transactions require the ACME
server to make outbound connections to potentially attacker-controlled servers,
and certificate issuance can require interactions with cryptographic hardware.

In addition, an attacker can also cause the ACME server to send validation
requests to a domain of its choosing by submitting authorization requests for
the victim domain.

All of these attacks can be mitigated by the application of appropriate rate
limits.  Issues closer to the front end, like POST body validation, can be
addressed using HTTP request limiting.  For validation and certificate requests,
there are other identifiers on which rate limits can be keyed.  For example, the
server might limit the rate at which any individual account key can issue
certificates, or the rate at which validation can be requested within a given
subtree of the DNS.


## CA Policy Considerations

The controls on issuance enabled by ACME are focused on validating that a
certificate applicant controls the identifier he claims.  Before issuing a
certificate, however, there are many other checks that a CA might need to
perform, for example:

* Has the client agreed to a subscriber agreement?
* Is the claimed identifier syntactically valid?
* For domain names:
  * If the leftmost label is a '*', then have the appropriate checks been
    applied?
  * Is the name on the Public Suffix List?
  * Is the name a high-value name?
  * Is the name a known phishing domain?
* Is the key in the CSR sufficiently strong?
* Is the CSR signed with an acceptable algorithm?

CAs that use ACME to automate issuance will need to ensure that their servers
perform all necessary checks before issuing.

# Operational Considerations

There are certain factors that arise in operational reality that operators of
ACME-based CAs will need to keep in mind when configuring their services.

[[ TODO: Other operational considerations ]]

## Default Virtual Hosts

In many cases, TLS-based services are deployed on hosted platforms that use
the Server Name Indication (SNI) TLS extension to distinguish between
different hosted services or "virtual hosts".  When a client initiates a
TLS connection with an SNI value indicating a provisioned host, the hosting
platform routes the connection to that host.

When a connection come in with an unknown SNI value, one might expect the
hosting platform to terminate the TLS connection.  However, some hosting
platforms will choose a virtual host to be the "default", and route connections
with unknown SNI values to that host.

In such cases, the owner of the default virtual host can complete a TLS-based challenge (e.g., "tls-sni-01")
for any domain with an A record that points to the hosting platform.  This could
  result in mis-issuance in cases where there are multiple hosts with different
  owners resident on the hosting platform.

A CA that accepts TLS-based proof of domain control should attempt to check
whether a domain is hosted on a domain with a default virtual host before
allowing an authorization request for this host to use a TLS-based challenge.
A default virtual host can be detected by initiating TLS connections to the host
with random SNI values within the namespace used for the TLS-based challenge
(the "acme.invalid" namespace for "tls-sni-01").


# Acknowledgements

In addition to the editors listed on the front page, this document has benefited
from contributions from a broad set of contributors, all the way back to its
inception.

* Peter Eckersley, EFF
* Eric Rescorla, Mozilla
* Seth Schoen, EFF
* Alex Halderman, University of Michigan
* Martin Thomson, Mozilla
* Jakub Warmuz, University of Oxford

This document draws on many concepts established by Eric Rescorla's "Automated
Certificate Issuance Protocol" draft.  Martin Thomson provided helpful guidance
in the use of HTTP.
