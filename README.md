# Branch Protection Enforcer App

* [Challenge](#challenge)
* [Demo](#demo)
* [Roadmap](#roadmap)
* [Contributing](#contributing)
* [Known Limitations](#known-limitations)
* [Troubleshooting](#troubleshooting)

## Challenge

> "I need my people capable of creating GitHub repositories with minimal controls in place, but I can't give them `admin` permission."

For any company with regulatory controls around how the build and deliver products, there is a real challenge of how to make it easy for their developers to be productive with the minimal necessary controls in place.

* [IT General Control](https://en.wikipedia.org/wiki/ITGC)
* [Sarbanes Oxley](https://en.wikipedia.org/wiki/Sarbanes%E2%80%93Oxley_Act#Sarbanes%E2%80%93Oxley_Section_404:_Assessment_of_internal_control)
* [Secure Software Development Life Cycle](https://en.wikipedia.org/wiki/Software_development_security), etc.

The Branch Protection Enforcer App project is a GitHub App installed for a GitHub organization with a simple purpose:

1. Watch for newly created repositories
1. Create branch protection rule for the default branch
1. Create issue notifying the repository creator of branch protection rule created

[Back to the top](#branch-protection-enforcer-app)

## Demo

Example of GitHub branch protection rule created immediately after repository creation
![Branch protection rule created](docs/demo_new_repo_branch_protection.png)

Example of GitHub issue documenting branch protection rule created
![Issue created letting the repository creator know branch protection rule created](docs/demo_new_repo_issue.png)

[Back to the top](#branch-protection-enforcer-app)

## Roadmap

Base GitHub App
- [x] Supports being installed for an organization
- [x] Supports creating basic branch protection rule with sane defaults
- [x] Supports documenting work as issue

Enhancements
- [ ] GitHub Action workflow(s) for testing, packaging, and publishing container image and Ruby gem
- [ ] Documentation around installing releases
- [ ] Supports arbitrary default branch names  _(bug in repository create payload on default branch name)_
- [ ] Supports use cases repository does not support branch protection rules  _(GitHub Free plan only supports on public repositories)_
- [ ] Supports fine grained customizations of repositories based on arbitrary criteria  _(artisianal sausage making)_
- [ ] Supports installing [GitHub App from manifest](https://docs.github.com/en/developers/apps/building-github-apps/creating-a-github-app-from-a-manifest)  _(why not?)
- [ ] Supports rich webhook delivery responses  _(make it easier to troubleshoot on both ends)_

[Back to the top](#branch-protection-enforcer-app)

## Contributing

Are you some who gets this isn't a sexy challenge but means all the world to product developers that need to go fast?

Please help: consider [contributing to this project](CONTRIBUTING.md) so others can have the best GitHub experience!

[Back to the top](#branch-protection-enforcer-app)

## Known Limitations

* This is project is in its infancy and lacks some boilerplate efforts around building, packaging, testing, and promotion.
* Error handling and logging are not the most robust currently

[Back to the top](#branch-protection-enforcer-app)

## Troubleshooting

### Expiration time' claim ('exp') is too far in the future

When I first saw this issue, it was due to clock skew between the machine the app was running on versus GitHub.

You can compare your date/time against GitHub and even sync your clock with appropriate atomic clock:

```shell
$ date && curl -I https://api.github.com | grep -Fi "date"
$ sudo apt-get install ntpdate
$ sudo ntpdate pool.ntp.org
$ date && curl -I https://api.github.com | grep -Fi "date"
```

[Back to the top](#branch-protection-enforcer-app)