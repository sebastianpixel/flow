# flow

flow is a command line tool that links a few things I continuously happen to do in my every day life as a mobile developer.

It's based on the Atlassian stack (stash & JIRA server) and makes a few assumptions about

* workflows,
* existing JIRA issue types,
* (branch) naming conventions,
* the URLs of stash & JIRA (as subdomains of 'company.com', which is retrieved from 'git remote -v')
* the login is global and not based on the repo for example
* and probably a few things more…

flow is also a playground for me to try out things in Swift, the Swift Package Manager and in general to learn about new things I come across while implementing new features.

## Running it
flow requires macOS 10.2 with Swift 5 installed. The following will clone the repo, build the executable and create a symbolic link from your binaries folder to the executable:
```bash
git clone https://github.com/sebastianpixel/flow.git \
&& cd flow \
&& swift build -c release \
&& ln -s `pwd`/.build/release/flow /usr/local/bin/flow
```

## Commands
### Start working on an issue
`flow init <options>` will

* create a branch based on your selection from the last updated issues and their sub-tasks in the format `<issuetype>-<PROJECT>-<number>-<train-cased-issue-title>`,
* push the branch upstream,
* assign the JIRA issue to you and
* update its status to `In Progress`.

### Track To-Dos
Add, edit, complete, delete to-do items with `flow todo` relative to the current repo, branch or without such constraint (based on iCloud reminders).

### Create a PR
Use `flow pr <options>` to

* write the PR description in the editor specified in your global git config,
* select a destination branch (or just use the branch of the parent issue),
* assign the PR to reviewers (or pick the default reviewers of the repo) and
* update the JIRA issue to `Ready To Review`.
* `flow pr -m` finally merges the pull request and
* shows a list of status for the issue to select from.

### The full list
Taken from the usage description (`flow {,help,-h,--help}`):

```
flow <command> <options>

flow <global_flags> <options>
Flags that are not preceded by a command.
Options:
  -d, --debug
      Print networking requests, responses, received JSON,
shell commands with their output and errors.
  -h, --help
      Print the usage description.

flow add, a
Add untracked and unstaged files.

flow assign-issue, assign <options>
Assign an issue to a user.
Options:
  -h, --help
      Print the usage description of 'assign-issue'.
  -i, --issue <value>
      The key of the issue the user should be assigned to.
      If not specified flow will try to get the issue key from the currently checked out branch.
  -s, --self
      Assign the issue to yourself.
  -u, --unassign
      Remove assignee.

flow board, bo <options>
Open the JIRA board of the current sprint.
Options:
  -h, --help
      Print the usage description of 'board'.
  -p, --project <value>
      The JIRA project in which to search for the current sprint.

flow branch, br <options>
Show a list of branches to check out.
Options:
  -a, --all
      Select branch to checkout from all instead of only local (default)
  -e, --expression <value>
      Search for branch containing the specified regex pattern.
  -h, --help
      Print the usage description of 'branch'.
  -p, --parent
      Checkout branch of parent JIRA issue if there is one. Default to selecting a branch if not.

flow browse, b <options>
Browse remote repository or JIRA issue.
Options:
  -d, --directory
      Open the remote repository in the current directory (if -j was not set).
  -e, --expression <value>
      Search for branch or issue by regular expression.
  -h, --help
      Print the usage description of 'browse'.
  -i, --issue <value>
      Specify the number of an issue (or branch if -j | --jira was not set) to open.
      Provide either a number if the issue is in the same project as the one
      associated with the current branch (expects the branch to contain the
      issue key) or a complete key (like 'PROJECT-1234').
  -j, --jira
      Browse JIRA issue instead of remote repository (default).
  -p, --parent
      Open parent issue or branch of current issue if there is one.
      Otherwise fall back to current.
  -P, --pull-request
      Open pull request of current branch if there is one or open currently
      open pull requests in current repository (if -j was not set).

flow commit, cm <options>
Create a commit in the current repository. If no message was provided
with the -m | --message argument a message template will be opened
similar to what you's see with 'git commit --verbose'.
Options:
  -h, --help
      Print the usage description of 'commit'.
  -i, --issue
      Prepend the commit message with the current JIRA issue's key.
  -m, --message <value> ...
      The commit's message.
  -p, --push
      Push after committing.

flow generate-readme, readme
Generate README.md.

flow help <options>
Print the usage description.
Options:
  -h, --help
      Print the usage description of 'help'.
  -A, --no-ansi
      Omit ansi formatting codes.
  -P, --no-pager
      Do not show help description in pager but write to stdout.

flow init <options>
Start working on a JIRA issue.
Either provide an JIRA issue key directly (via -i | --issue argument)
or provide the JIRA project name (via -p | --project argument) to select
an issue. The issues will be shown in the form of branch names.

With the provided issue key or the selected line
* a branch for that issue will be checked out and
* set to track a branch in the remote repository.
* Optionally the selected issue will be assigned to the current user
* and its status will be updated to "In Progress".
Options:
  -h, --help
      Print the usage description of 'init'.
  -i, --issue <value>
      Specify the issue key for which to create a branch.
  -p, --project <value>
      The JIRA project in which to search for issues.

flow merge, m <options>
Merge another branch into the current one.
Options:
  -a, --all
      Select branch to merge into current one from all branches in the repository.
  -b, --branch <value>
      Specify a branch to merge into the current one.
      If not set a selector will be shown to pick from local
      (default) or all branches in the repository.
  -e, --expression <value>
      Search for a branch to merge containing the specified regex pattern.
  -h, --help
      Print the usage description of 'merge'.
  -p, --parent
      Merge branch of parent issue into the current branch.
  -P, --pull-source
      Pull source branch before merging.

flow playground, play, p
Create a playground in temporary files and open it.

flow pull-request, pr <options>
Create a pull request for the current branch:
* fetch the default reviewers if -d | --default was set or
  show a list of potential reviewers to select from,
* set them as reviewers,
* let's you select the base branch or take the parent
  branch if -p | --parent was selected,
* and move the current JIRA issue to 'Ready To Review'.

Alternatively to creating -m | --merge merges existing PRs.
Options:
  -b, --browse
      Show PR if created successfully.
  -c, --copy
      Copy description of PR with link to clipboard e.g. to paste it into Slack.
  -d, --default
      Fetch the default reviewers of the repository and set them as
      reviewers of the pull request if there are some.
  -h, --help
      Print the usage description of 'pull-request'.
  -m, --merge
      Select pull-request from the current repository to merge.
  -n, --no-edit
      Skip edit mode, create pull request with title only (taken from source branch).
  -p, --parent
      If current branch belongs to a sub-task this will look for the
      parent issue's branch and set it as destination of the pull request.

flow reminders, todos, todo, td <options>
Show and edit todos from iCloud reminders.
Options:
  -A, --add <value> ...
      Directly add new reminders (semicolon separated).
  -a, --all
      Show all reminders instead of those from current repository (default).
  -b, --branch
      Show only reminders created with the current branch checked out.
  -h, --help
      Print the usage description of 'reminders'.

flow remove, rm
Remove untracked and unstaged files.

flow remove-branch, rmb <options>
Remove local (default) or remote branches.
Options:
  -h, --help
      Print the usage description of 'remove-branch'.
  -r, --remote
      Remove remote branches.

flow rename-branch, rnb <options>
Rename current branch.
Options:
  -h, --help
      Print the usage description of 'rename-branch'.
  -k, --keep-current
      If not set current branch will be removed from remote.
  -n, --name <value>
      New name for current branch.

flow reset-login, reset
Reset username (saved in UserDefaults) and password (saved in Keychain).

flow resolve-conflicts, resolve
Open files with merge conflicts in vim tabs.

flow status, st
Set the status of the current JIRA issue.

flow xcopen, open, o
Open XCode workspace, project or playground in current working directory.
```