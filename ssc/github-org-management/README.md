# GitHub Org Management

The SPIFFE Steering Committee (SSC) is responsible for administrating the 
SPIFFE GitHub Organization.

To keep things organized and auditable, the SSC uses [peribolos](PERIBOLOS.md)
to manage the org's teams and members.

The guidance in this document is designed to ensure that membership and access
to repositories is managed in a consistent and centralized way.

## Org Ownership

As well as being members of the `ssc` GitHub team, SSC members should also
directly hold the `Owner` role in the SPIFFE GitHub org.

In addition to the SSC, the `thelinuxfoundation` GitHub account should hold
the `Owner` role in the SPIFFE GitHub org.

Org Ownership is managed manually.

## Repository Management

When assigning privileges or code ownership for a repository, it should be 
preferred to assign to a team rather than individuals. This ensures that team
membership is coherent to actual privileges.

For small/tiny projects - it may be appropriate to directly grant privileges 
to individuals. However, consider if creating a team may be more appropriate!

## Team Management

Teams should be created as appropriate for maintainership of SPIFFE umbrella
repositories.

In GitHub, members of teams can be a `member` or a `maintainer`. Confusingly,
`maintainer` conveys the ability to manage membership of the team itself
directly within GitHub. Since team membership is managed via peribolos, the
`maintainer` team role is not used. All members of a team should hold the
`member` role.
