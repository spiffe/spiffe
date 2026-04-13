# The SPIFFE Filesystem Delivery Standard

## Status of this Memo {#memo-status}

This document specifies an identity API standard for the internet community, and
requests discussion and suggestions for improvements. Distribution of this
document is unlimited.

## Abstract {#abstract}

Many applications run in environments where SPIFFE certificates and trust
bundles are more easily delivered via the filesystem, rather than the SPIFFE
Workload API.  This specification gives applications and identity provisioning
systems a concrete target to aim for:
* How identity provisioning systems should write SPIFFE SVIDs.
* How identity provisioning systems should write SPIFFE trust bundles for the
  local and any federated trust domains.
* Where applications should look to discover these credentials.
* How applications should read them.

## Table of Contents {#toc}

1\. [Participants](#participants)
2\. [Credential Folder](#credential-folder)
2\.1\. [Credential Bundle](#credential-bundle)
2\.2\. [Trust Bundles](#trust-bundles)
3\. [Application Behavior](#application-behavior)
3\.1\. [Locating the Credential Folder](#locating-the-credential-folder)
3\.2\. [Loading and Refreshing the Credential Bundle](#loading-and-refreshing-the-credential-bundle)
3\.3\. [Validating Peer SPIFFE Certificates](#validating-peer-spiffe-certificates)
Appendix A. [Filesystem Delivery and the Workload API](#appendix-filesystem-delivery-vs-the-workload-api)
Appendix B. [Example Kubernetes Setup](#appendix-example-kubernetes-setup)


## 1. Participants {#participants}

**Provisioning System:** The software stack responsible for distributing X.509
SVIDS and trust domain federation configuration to individual applications.

For applications running in a Kubernetes cluster, this might be composed of
kubelet, kube-apiserver, and a SPIFFE signer plugin, working through the Pod
Certificates mechanism to deliver certificates into individual application pod
filesystems.

For applications running directly on a machine or VM, this may be a system
daemon or node agent that writes X.509 SVIDs to a particular folder in the
filesystem.

**Application:** An individual application that expects to:
* Load an X.509 SVID from the filesystem, and use it to connect to other peers.
* Verify X.509 SVIDs presented by peers, including peers in different trust
  domains.

## 2. Credential Folder {#credential-folder}

A credential folder contains:
* A credential bundle, named `credential-bundle.pem`
* One or more trust bundles, named `<trust-domain>.trust-bundle.pem`

A credential folder MAY contain other files and directories, used by the
provisioning system to track state and atomically update the credentials.  The
application SHOULD ignore this additional content.

### 2.1 Credential Bundle {#credential-bundle}

A credential bundle file contains the application's private key and certificate
chain.  Combining these together into one file ensures that the provisioning
system can rotate the key and certificate atomically.  (Note that, for safety,
the application must also read this file atomically, as described in section
3.2).

The credential bundle consists of two or more PEM blocks.  The first block must
be of type PRIVATE KEY, and contain a PKCS#8-serialized private key.

The remaining PEM blocks must be of type CERTIFICATE, and contain the
application's certificate chain, in leaf-to-root order.  The leaf certificate
must be issued to the public key derived from the PRIVATE KEY block.  The leaf
certificate SHOULD be an X.509 SVID.

The certificate chain MAY contain the trust anchor ("root certificate") of the
chain, or it MAY stop at the certificate preceding the trust anchor.

The credential bundle:
* MUST NOT contain any other PEM block types.
* MUST NOT contain any inter-block data.
* MUST NOT contain any PEM blocks that have PEM headers.

The provisioning system SHOULD update the credential bundle on the filesystem
with a new key and certificate chain before the leaf certificate currently in
the bundle expires. The provisioning system SHOULD make these updates
atomically, so that an application reading the credential bundle reads either
the complete old content or the complete new content, with no intermediate
state.

### 2.2 Trust Bundles {#trust-bundles}

The credential folder will contain one or more trust bundles, one per trust
domain that the provisioning system is configured to federate with.

Each trust bundle file MUST be named following the pattern
"<trust-domain>.trust-bundle.pem".  The file contents are one or more PEM
CERTIFICATE blocks, each with a PKIX-serialized certificate that is a trust
anchor for the trust domain.

A trust bundle file:
* MUST NOT contain any other PEM block types.
* MUST NOT contain any inter-block data.
* MUST NOT contain any PEM blocks that have PEM headers.

The provisioning system SHOULD update the trust bundles on the filesystem as the
system's federation configuration changes.  The provisioning system SHOULD make
these updates atomically, so that an application reading a trust bundle reads
either the complete old content, or the complete new content, with no
intermediate state.

## 3. Application Behavior {#application-behavior}

### 3.1 Locating the Credential Folder {#locating-the-credential-folder}
The application SHOULD search for a SPIFFE credential folder with the following
procedure:
1. The application should first follow the procedure from [SPIFFE Workload
   Endpoint, Section
   4](https://spiffe.io/docs/latest/spiffe-specs/spiffe_workload_endpoint/#4-locating-the-endpoint)
   to determine if the SPIFFE Workload API is available.
2. If the applications supports an application-specific configuration mechanism
   for picking a SPIFFE credential folder, it use the credential folder
   indicated by that configuration.
3. Otherwise, if the SPIFFE_CREDENTIAL_FOLDER environment variable is set, and
   contains a valid path for the platform, the application should treat that
   folder as the credential folder to use.
4. Otherwise, the application should check for the existence of a
   platform-specific default credential folder, and use it if it is present.
5. Otherwise, the application has not been issued SPIFFE credentials.

On platforms that use the Filesystem Hierarchy Standard, such as Linux, the
application should check the following default credential folders, in descending
order of preference:
1) `/run/secrets/workload-spiffe-credentials/credential-bundle.pem`
2) `/var/run/secrets/workload-spiffe-credentials/credential-bundle.pem`
  
On most systems, `/var/run` is a symlink to `/run`, or vice-versa.  However this
may not be true in some containerized environments, especially those that use
distroless base images.

### 3.2 Loading and Refreshing the Credential Bundle {#loading-and-refreshing-the-credential-bundle}

Before the application can use its SPIFFE credentials, it needs to load the
credential bundle from the filesystem.

When loading the credential bundle, the application SHOULD complete the load in
a single open/read/close cycle.  In particular, the application SHOULD NOT have
one open/read/close cycle to read the private key, and another open/read/close
cycle to read the certificate chain.

Note: If the application does use more than one open/read/close cycle, then it
is possible that the application may load a mismatched private key and
certificate, if the provisioning system rotated the credentials between the two
open/read/close cycles.  This is true even if the provisioning system atomically
writes the updated content.

The provisioning system may periodically update the credential bundle on the
filesystem.  The application SHOULD reload the credential bundle within five
minutes of the provisioning system updating it.  The application SHOULD NOT
assume that the updated bundle will have any commonality with the previous
bundle.  For example, the type of the private key may be different, or the
certificate may be issued from a different root, with different intermediates.

### 3.3 Validating Peer SPIFFE Certificates {#validating-peer-spiffe-certificates}

In order to verify a SPIFFE X.509 SVID presented by a peer, the application
needs to determine the correct trust bundle for the peers trust domain.

Once the application has parsed the peer's trust domain from the unverified peer
X.509 SVID, the application should load the corresponding trust domain's trust
bundle from the credential folder.  If no trust bundle file is present for the
peer's trust domain, the application SHOULD assume that SPIFFE federation has
not been configured with the peer, and fail to verify the peer's certificate.

The provisioning system may periodically update the number and contents of the
per-trust-domain trust bundles in the filesystem.  The application MAY cache the
presence, absence, and contents of each trust domain's trust bundle in memory,
but it SHOULD reflect updates from the filesystem within five minutes of them
occurring.

The application SHOULD handle de-federation; if it has loaded a trust bundle for
trust domain X, and then X's trust bundle is removed from the credential folder,
the application SHOULD begin failing to verify certificates for trust domain X
within 5 minutes.

## Appendix A: Filesystem Delivery Versus the Workload API {#filesystem-delivery-vs-the-workload-api}

There are currently two standards for SPIFFE-conforming applications to retrieve
credentials and trust bundles: the Workload API, and Filesystem Delivery.  These
standards, broadly speaking, cover the same functionality.  The Workload API
predates Filesystem Delivery, and is the preferred solution, all else equal.

Filesystem Delivery exists because, in certain computing environments, such as
Kubernetes, it is easier for the environment to furnish *files* to the workload,
rather than making a TCP or Unix socket service available.  It's also lower
effort to read files from workloads, but, as described in [Section
3.2](#loading-and-refreshing-the-credential-bundle), it still requires care.

Given these two choices, which should you use?

If you are writing or maintaining an application that needs to load and use
SPIFFE credentials, you should ideally support both the Workload API and
Filesystem Delivery, following the procedure from [Section
3.1](#locating-the-credential-folder) to select.

If supporting both is not feasible, then consider which standard the SPIFFE
identity provisioning you are most likely to use supports.

If you are writing or maintaining a SPIFFE X.509 identity provisioning system,
then, again, ideally you would support both mechanisms, however (as in the case
of Kubernetes) the Workload API may be less feasible.

## Appendix B: Example Kubernetes Setup {#example-kubernetes-setup}

Kubernetes provides two built-in mechanisms that can be used together to
implement the SPIFFE Filesystem Delivery API:
* Pod Certificates are a pluggable mechanism to issue and automatically refresh
  certificates to application pods.  Each pod gets an independent private key,
  which never leaves the node where the pod is running.  The private key and
  certificate chain can be written into a credential bundle in the pod's
  filesystem.
* Cluster Trust Bundles are bags of root certificates with a unique name.  They
  can be mounted into a pod's filesystem, and the content in the filesystem
  automatically updates as the Cluster Trust Bundles are updated.

For example, we could implement a controller that handles the signer name
`spiffe.example/identity`.  This controller would have two responsibilities:
* Respond to PodCertificateRequests from pods that want a certificate from the
  `spiffe.example/identity`.  The precise details of the issued certificate are
  up to the controller.  In this case, assume that it is configured to issue
  certificates with SPIFFE IDs like
  `spiffe://domain-a.myorg.example/ns/<namespace>/sa/<service-account>`.
* Maintain a set of ClusterTrustBundles associated with
  `spiffe.example/identity`.  There are many potential ways to structure the set
  of ClusterTrustBundles, but one that would work is to use labels to divide
  them:
    * `k8s.spiffe.io/canarying`: Possible values of `live` or `preview`.  Most
      application pods would always select ClusterTrustBundles with the value
      `live`, but some may be configured to select `preview`, so that actions
      like rotating a CA or federating with a new trust domain can be previewed
      on some fraction of your application fleet.
    * `k8s.spiffe.io/workload-trust-domain`:  The label's value is a trust
      domain X; workloads that are part of X should load this trust bundle.
    * `k8s.spiffe.io/peer-trust-domain`: The label's value is a trust domain Y;
      workloads that are communicating with a peer in Y should load this trust
      bundle.

Note: Drawing a distinction between a *workload's* trust domain and its *peer's*
trust domain is necessary (but non-obvious) when workloads from multiple trust
domains can be mixed together in one cluster.  Each trust domain should have its
own federation configuration; given three trust domains A, B, and C, if A is
federated with C, workloads in B should not automatically also be federated just
because they happen to run in the same Kubernetes cluster.

This information can then be mounted into an application pod in a way that forms
a valid SPIFFE credential folder:

```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: client
  namespace: spiffe-example
  labels:
    app: client
spec:
  replicas: 1
  selector:
    matchLabels:
      app: client
  template:
    metadata:
      labels:
        app: client
    spec:
      restartPolicy: Always
      containers:
      - name: client
        image: debian
        command: ["sleep", "infinity"]
        volumeMounts:
        - name: default-spiffe-credentials
          mountPath: /run/workload-spiffe-credentials
          readOnly: true
      volumes:
      - name: default-spiffe-credentials
        projected:
          sources:
          - clusterTrustBundle:
              signerName: spiffe.example/identity
              labelSelector:
                matchLabels:
                  "k8s.spiffe.io/canarying":             "live"
                  "k8s.spiffe.io/workload-trust-domain": "a.myorg.example"
                  "k8s.spiffe.io/peer-trust-domain":     "a.myorg.example"
              path: a.myorg.example.trust-bundle.pem
          # This workload needs to federate with b.myorg.example, so it needs the appropriate bundle.
          - clusterTrustBundle:
              signerName: spiffe.example/identity
              labelSelector:
                matchLabels:
                  "k8s.spiffe.io/canarying":             "live"
                  "k8s.spiffe.io/workload-trust-domain": "a.myorg.example"
                  "k8s.spiffe.io/peer-trust-domain":     "b.myorg.example"
              path: b.myorg.example.trust-bundle.pem
          - podCertificate:
              signerName: spiffe.example/identity
              keyType: ECDSAP256
              credentialBundlePath: credential-bundle.pem
```



