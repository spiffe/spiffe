# Contributing to SPIFFE

* First, [README](/README.md) to become familiar with how the SPIFFE project is managed
* Make sure you're familiar with our [Coding Conventions](#conventions) when appropriate
* Make sure you've signed the SPIFFE [CLA](/CLA.md)

If you're new to SPIFFE, we recommend that you join us on the mailing lists and Slack to discuss any potential changes you'd like to see made.

If your proposal comes under the purview of a SIG, reach out to the SIG lead and seek their feedback
first (bugfixes and changes with minor impact don't need this). The SIG lead may refer you to the
broader group.

## Sending a pull request

1. Fork the repo
1. Commit changes to your fork
1. Ensure your branch is based on the latest commit in `master`
1. Ensure all tests pass (see project docs for more information)
1. Open a [pull request](https://help.github.com/articles/creating-a-pull-request-from-a-fork/)
  against the upstream `master` branch

All changes to SPIFFE projects must be code reviewed in a pull request (this goes for everyone, even
those who have merge rights).

## After your pull request is submitted

Pull requests are approved according to the process described in our [governance
policies](/GOVERNANCE.md). At least one maintainer must approve the pull request, and for large
changes, another independent reviewer must approve it too.

Once your pull request is submitted, it's your responsibility to:

* Respond to reviewer's feedback
* Keep it merge-ready at all times until it has been approved and actually merged.

Following approval, the PR will be merged by the last maintainer to approve the request.

## Coding Conventions <a name="conventions"></a>

Generally, these are the coding conventions SPIFFE projects should follow. Maintainers will consider
these conventions when reviewing pull requests.

* **General**
  * Command-line flags should use dashes, not underscores
  * Plugin and API protobuf comments are expected to be accompanied with markdowns generated with
    [protoc-gen-doc](https://github.com/pseudomuto/protoc-gen-doc)
  * All filenames should be lowercase
  * Source files and directories use underscores, no dashes (snake case)
  * Documents directories and filenames should use dashes rather than underscores (kebab case)
  * Most significant functionality must come with unit tests
  * Significant features should have integration and/or end-to-end tests
  * Unit tests should be fully hermetic. Only access resources in the test binary
  * Concurrent unit test runs must pass
* **Go**
  * [Effective Go](https://golang.org/doc/effective_go.html)
  * [Go's commenting conventions](http://blog.golang.org/godoc-documenting-go-code)
* **Bash**
  * [Google shell conventions](https://google.github.io/styleguide/shell.xml)
* **Python**
  * [PEP8](https://www.python.org/dev/peps/pep-0008/)

#### Logging conventions

| Level | Description |
| :---: | :--- |
| ERROR | Always an error |
| WARNING | Something unexpected, but probably not an error |
| INFO | Has multiple levels |
| V(0) | Generally useful for this to ALWAYS be visible to an operator  <ul><li>Programer Errors</li><li>Logging extra info about a panic</li><li>CLI argument handling</li></ul> |
| V(1) | A reasonable default log level if you don't want verbosity <ul><li>Information about config (listening on X, watching Y )</li><li>Errors that repeat frequently that relate to conditions that can be corrected.</li></ul>|
| V(2) | Useful steady state information about the service and important log messages that may correlate to significant changes in the system. <ul><li>Logging HTTP requests and their exit code</li><li>System state changing (killing pod)</li><li>Controller state change events</li></ul>|
| V(3) | More info about system state changes |  
| V(4) | Debug level verbosity |

The practical default level is V(2). Developers and QE environments
may wish to run at V(3) or V(4).  

#### Third-party code

When third-party code must me included, all licenses must be preserved. This includes modified
third-party code and excerpts, as well

#### Repositories and Licenses

All repositories under this project should include:

* A detailed `README.md` which includes a link back to this file
* A `LICENSE` file with the Apache 2.0 license
* A [CODEOWNERS](https://help.github.com/articles/about-codeowners/) file listing the maintainers

All code projects should use the [Apache License version
2.0](https://www.apache.org/licenses/LICENSE-2.0), and all documentation repositories should use the
[Creative Commons License version 4.0](https://creativecommons.org/licenses/by/4.0/legalcode)
