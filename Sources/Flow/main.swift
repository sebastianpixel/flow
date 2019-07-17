import Foundation
import Procedure
import Tool

Tool { flow in

    var debug = false
    let run = { Core(debug: debug, toolName: flow.toolName).run($0) }

    defer {
        if flow.arguments.isEmpty {
            run(PrintUsageDescription(usageDescription: flow.usageDescription(ansi: true), showInPager: true))
        }
    }

    flow.registerGlobalFlags(description: "Flags that are not preceded by a command.") { cmd in

        let help = cmd.option(shortName: "h",
                              longName: "help",
                              description: "Print the usage description.")

        let debugOption = cmd.option(shortName: "d",
                                     longName: "debug",
                                     description: """
                                     Print networking requests, responses, received JSON,
                                     shell commands with their output and errors.
                                     """)

        cmd.handler {
            debug = debugOption.wasSet
            if help.wasSet {
                run(PrintUsageDescription(usageDescription: flow.usageDescription(ansi: true), showInPager: true))
            }
        }
    }

    flow.registerCommand("help", description: "Print the usage description.") { cmd in

        let noAnsi = cmd.option(shortName: "A", longName: "no-ansi", description: "Omit ansi formatting codes.")
        let noPager = cmd.option(shortName: "P", longName: "no-pager", description: "Do not show help description in pager but write to stdout.")

        cmd.handler {
            run(PrintUsageDescription(usageDescription: flow.usageDescription(ansi: !noAnsi.wasSet), showInPager: !noPager.wasSet))
        }
    }

    flow.registerCommand("commit", "cm", description: """
    Create a commit in the current repository. If no message was provided
    with the -m | --message argument a message template will be opened
    similar to what you's see with 'git commit --verbose'.
    """) { cmd in

        let message = cmd.arguments(String.self,
                                    shortName: "m",
                                    longName: "message",
                                    description: "The commit's message.")

        let prependWithIssueKey = cmd.option(shortName: "i",
                                             longName: "issue",
                                             description: "Prepend the commit message with the current JIRA issue's key.")

        let push = cmd.option(shortName: "p",
                              longName: "push",
                              description: "Push after committing.")

        cmd.handler {
            run(CreateCommit(message: message.value.joined(separator: " "),
                             prependWithIssueKey: prependWithIssueKey.wasSet))

            if push.wasSet {
                run(Push())
            }
        }
    }

    flow.registerCommand("browse", "b", description: "Browse remote repository or JIRA issue.") { cmd in

        let jira = cmd.option(shortName: "j",
                              longName: "jira",
                              description: "Browse JIRA issue instead of remote repository (default).")

        let issue = cmd.argument(String.self,
                                 shortName: "i",
                                 longName: "issue",
                                 description: """
                                 Specify the number of an issue (or branch if -j | --jira was not set) to open.
                                       Provide either a number if the issue is in the same project as the one
                                       associated with the current branch (expects the branch to contain the
                                       issue key) or a complete key (like 'PROJECT-1234').
                                 """)

        let expression = cmd.argument(String.self,
                                      shortName: "e",
                                      longName: "expression",
                                      description: "Search for branch or issue by regular expression.")

        let currentDirectory = cmd.option(shortName: "d",
                                          longName: "directory",
                                          description: "Open the remote repository in the current directory (if -j was not set).")

        let pullRequest = cmd.option(shortName: "P",
                                     longName: "pull-request",
                                     description: """
                                     Open pull request of current branch if there is one or open currently
                                           open pull requests in current repository (if -j was not set).
                                     """)

        let openParent = cmd.option(shortName: "p",
                                    longName: "parent",
                                    description: """
                                    Open parent issue or branch of current issue if there is one.
                                          Otherwise fall back to current.
                                    """)

        cmd.handler {
            let procedure: Procedure
            if jira.wasSet {
                procedure = BrowseIssue(issueKey: issue.value,
                                        expression: expression.value,
                                        openParent: openParent.wasSet)
            } else {
                let branchToOpen: BrowseGit.Branch
                if let expression = expression.value {
                    branchToOpen = .expression(expression)
                } else if let issue = issue.value {
                    branchToOpen = .issue(issue)
                } else if openParent.wasSet {
                    branchToOpen = .parent
                } else {
                    branchToOpen = .current
                }

                procedure = BrowseGit(currentDirectory: currentDirectory.wasSet,
                                      pullRequest: pullRequest.wasSet,
                                      branchToOpen: branchToOpen)
            }
            run(procedure)
        }
    }

    flow.registerCommand("init", description: """
    Start working on a JIRA issue.
    Either provide an JIRA issue key directly (via -i | --issue argument)
    or provide the JIRA project name (via -p | --project argument) to select
    an issue. The issues will be shown in the form of branch names.

    With the provided issue key or the selected line
    * a branch for that issue will be checked out and
    * set to track a branch in the remote repository.
    * Optionally the selected issue will be assigned to the current user
    * and its status will be updated to "In Progress".
    """) { cmd in

        let project = cmd.argument(String.self,
                                   shortName: "p",
                                   longName: "project",
                                   description: "The JIRA project in which to search for issues.")

        let issueKey = cmd.argument(String.self,
                                    shortName: "i",
                                    longName: "issue",
                                    description: "Specify the issue key for which to create a branch.")

        cmd.handler {
            run(Initialize(jiraProject: project.value,
                           issueKey: issueKey.value))
        }
    }

    flow.registerCommand("status", "st", description: "Set the status of the current JIRA issue.") {
        $0.handler {
            run(SetTransition())
        }
    }

    flow.registerCommand("board", "bo", description: "Open the JIRA board of the current sprint.") { cmd in

        let project = cmd.argument(String.self,
                                   shortName: "p",
                                   longName: "project",
                                   description: "The JIRA project in which to search for the current sprint.")

        cmd.handler {
            run(OpenCurrentSprint(jiraProject: project.value))
        }
    }

    flow.registerCommand("branch", "br", description: "Show a list of branches to check out.") { cmd in

        let all = cmd.option(shortName: "a",
                             longName: "all",
                             description: "Select branch to checkout from all instead of only local (default)")

        let parent = cmd.option(shortName: "p",
                                longName: "parent",
                                description: "Checkout branch of parent JIRA issue if there is one. Default to selecting a branch if not.")

        let expression = cmd.argument(String.self,
                                      shortName: "e",
                                      longName: "expression",
                                      description: "Search for branch containing the specified regex pattern.")

        cmd.handler {
            run(CheckoutBranch(all: all.wasSet,
                               parent: parent.wasSet,
                               pattern: expression.value))
        }
    }

    flow.registerCommand("remove-branch", "rmb", description: "Remove local (default) or remote branches.") { cmd in

        let remote = cmd.option(shortName: "r",
                                longName: "remote",
                                description: "Remove remote branches.")

        cmd.handler {
            run(remote.wasSet ? RemoveRemoteBranches() : RemoveLocalBranches())
        }
    }

    flow.registerCommand("pull-request", "pr", description: """
    Create a pull request for the current branch:
    * fetch the default reviewers if -d | --default was set or
      show a list of potential reviewers to select from,
    * set them as reviewers,
    * let's you select the base branch or take the parent
      branch if -p | --parent was selected,
    * and move the current JIRA issue to 'Ready To Review'.

    Alternatively to creating -m | --merge merges existing PRs.
    """) { cmd in

        let defaultReviewers = cmd.option(shortName: "d",
                                          longName: "default",
                                          description: """
                                          Fetch the default reviewers of the repository and set them as
                                                reviewers of the pull request if there are some.
                                          """)

        let parentBranch = cmd.option(shortName: "p",
                                      longName: "parent",
                                      description: """
                                      If current branch belongs to a sub-task this will look for the
                                            parent issue's branch and set it as destination of the pull request.
                                      """)

        let noEdit = cmd.option(shortName: "n",
                                longName: "no-edit",
                                description: "Skip edit mode, create pull request with title only (taken from source branch).")

        let merge = cmd.option(shortName: "m",
                               longName: "merge",
                               description: "Select pull-request from the current repository to merge.")

        let browseAfterSuccessfulCreation = cmd.option(shortName: "b",
                                                       longName: "browse",
                                                       description: "Show PR if created successfully.")

        cmd.handler {
            if merge.wasSet {
                run(MergePullRequest())
            } else {
                run(CreatePullRequest(defaultReviewers: defaultReviewers.wasSet,
                                      parentBranch: parentBranch.wasSet,
                                      noEdit: noEdit.wasSet,
                                      browseAfterSuccessfulCreation: browseAfterSuccessfulCreation.wasSet))
            }
        }
    }

    flow.registerCommand("merge", "m", description: "Merge another branch into the current one.") { cmd in

        let branch = cmd.argument(String.self,
                                  shortName: "b",
                                  longName: "branch",
                                  description: """
                                  Specify a branch to merge into the current one.
                                        If not set a selector will be shown to pick from local
                                        (default) or all branches in the repository.
                                  """)

        let all = cmd.option(shortName: "a",
                             longName: "all",
                             description: "Select branch to merge into current one from all branches in the repository.")

        let parent = cmd.option(shortName: "p",
                                longName: "parent",
                                description: "Merge branch of parent issue into the current branch.")

        let expression = cmd.argument(String.self,
                                      shortName: "e",
                                      longName: "expression",
                                      description: "Search for a branch to merge containing the specified regex pattern.")

        let shouldPullSourceBranch = cmd.option(shortName: "P", longName: "pull-source", description: "Pull source branch before merging.")

        cmd.handler {
            run(Merge(branch: branch.value,
                      all: all.wasSet,
                      parent: parent.wasSet,
                      expression: expression.value,
                      shouldPullSourceBranch: shouldPullSourceBranch.wasSet))
        }
    }

    flow.registerCommand("playground", "play", "p", description: "Create a playground in temporary files and open it.") {
        $0.handler {
            run(OpenPlayground())
        }
    }

    flow.registerCommand("xcopen", "open", "o", description: "Open XCode workspace, project or playground in current working directory.") {
        $0.handler {
            run(XCOpen())
        }
    }

    flow.registerCommand("reset-login", "reset", description: "Reset username (saved in UserDefaults) and password (saved in Keychain).") {
        $0.handler {
            run(ResetLogin())
        }
    }

    flow.registerCommand("add", "a", description: "Add untracked and unstaged files.") {
        $0.handler {
            run(HandleFiles(.add, untracked: true, unstaged: true))
        }
    }

    flow.registerCommand("remove", "rm", description: "Remove untracked and unstaged files.") {
        $0.handler {
            run(HandleFiles(.remove, untracked: true, unstaged: true))
        }
    }

    flow.registerCommand("generate-readme", "readme", description: "Generate README.md.") {
        $0.handler {
            run(GenerateReadme(usageDescription: flow.usageDescription(ansi: false)))
        }
    }

    flow.registerCommand("rename-branch", "rnb", description: "Rename current branch.") { cmd in

        let newName = cmd.argument(String.self,
                                   shortName: "n",
                                   longName: "name",
                                   description: "New name for current branch.")

        let keepCurrentOnRemote = cmd.option(shortName: "k",
                                             longName: "keep-current",
                                             description: "If not set current branch will be removed from remote.")

        cmd.handler {
            run(RenameBranch(newName: newName.value,
                             keepCurrentOnRemote: keepCurrentOnRemote.wasSet))
        }
    }

    flow.registerCommand("resolve-conflicts", "resolve", description: "Open files with merge conflicts in vim tabs.") {
        $0.handler {
            run(ResolveConflicts())
        }
    }

    flow.registerCommand("assign-issue", "assign", description: "Assign an issue to a user.") { cmd in

        let issueKey = cmd.argument(String.self,
                                    shortName: "i",
                                    longName: "issue",
                                    description: """
                                    The key of the issue the user should be assigned to.
                                          If not specified flow will try to get the issue key from the currently checked out branch.
                                    """)
        let assignToSelf = cmd.option(shortName: "s",
                                      longName: "self",
                                      description: "Assign the issue to yourself.")
        let unassign = cmd.option(shortName: "u",
                                  longName: "unassign",
                                  description: "Remove assignee.")

        cmd.handler {
            run(AssignIssue(issueKey: issueKey.value, assignToSelf: assignToSelf.wasSet, unassign: unassign.wasSet))
        }
    }

    flow.registerCommand("reminders", "todos", "todo", "td", description: "Show and edit todos from iCloud reminders.") { cmd in

        let showAll = cmd.option(shortName: "a",
                                 longName: "all",
                                 description: "Show all reminders instead of those from current repository (default).")
        let showOnlyBranch = cmd.option(shortName: "b",
                                        longName: "branch",
                                        description: "Show only reminders created with the current branch checked out.")
        let remindersToAdd = cmd.arguments(String.self,
                                           shortName: "A",
                                           longName: "add",
                                           description: "Directly add new reminders (semicolon separated).")

        cmd.handler {
            let scope: Reminders.Scope
            if showAll.wasSet {
                scope = .all
            } else if showOnlyBranch.wasSet {
                scope = .branch
            } else {
                scope = .repo
            }
            run(Reminders(scope: scope, remindersToAdd: remindersToAdd.value))
        }
    }
}
