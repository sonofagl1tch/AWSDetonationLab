# Changelog

## v2.2
### Changed
* Inspector logs are fetched directly from the AWS API instead of being fetched from an S3 bucket.

## v2.1
### Added
* Automate setting `wazuh-alerts-3.x-*` as Kibana's default index pattern ([#64](https://github.com/sonofagl1tch/AWSDetonationLab/pull/64/)).
* Automate import of custom dashboards and visualizations into Kibana ([#68](https://github.com/sonofagl1tch/AWSDetonationLab/pull/68/)).

### Fixed
* Retrieve AMI IDs dynamically instead of having hardcoded values ([#66](https://github.com/sonofagl1tch/AWSDetonationLab/pull/66)).

## v2.0
### Added
* Added `apache` user to `wheel` group in Linux vulnerable server ([#20](https://github.com/sonofagl1tch/AWSDetonationLab/pull/20)).
* Added parameters in CF script to select instance type ([#27](https://github.com/sonofagl1tch/AWSDetonationLab/pull/27), [#31](https://github.com/sonofagl1tch/AWSDetonationLab/pull/31) and [#34](https://github.com/sonofagl1tch/AWSDetonationLab/pull/34)).
* Allow deploying multiple detonation labs in the same account by using randomly generated names ([#33](https://github.com/sonofagl1tch/AWSDetonationLab/pull/33)).
* Install Wazuh agent in both bastion and red team instances ([#47](https://github.com/sonofagl1tch/AWSDetonationLab/pull/47)).
* Add support for Wazuh's VirusTotal integration ([#58](https://github.com/sonofagl1tch/AWSDetonationLab/pull/58)).

### Fixed
* Additional Wazuh configuration is appended to the default one instead of rewriting all Wazuh configuration ([#26](https://github.com/sonofagl1tch/AWSDetonationLab/pull/26) and [#35](https://github.com/sonofagl1tch/AWSDetonationLab/pull/35)).
* Fixed typo in CF script: _firehost_ to _firehose_ ([#37](https://github.com/sonofagl1tch/AWSDetonationLab/pull/37)).
* Fixed bug replacing AWS secret key in Wazuh configuration ([#62](https://github.com/sonofagl1tch/AWSDetonationLab/pull/62)).

### Changed
* Wazuh agents registration using `authd` service ([#19](https://github.com/sonofagl1tch/AWSDetonationLab/pull/19) and [#39](https://github.com/sonofagl1tch/AWSDetonationLab/pull/39))
* AMI images has been updated to `amzn-ami-hvm-2018.03.0.20181119-x86_64-gp2` and `Windows_Server-2012-R2_RTM-English-64Bit-Base-2018.10.14` ([#52](https://github.com/sonofagl1tch/AWSDetonationLab/pull/52)).
* Update Java download script ([#43](https://github.com/sonofagl1tch/AWSDetonationLab/pull/43)).
* Implemented new method of logging VPC Flow directly to S3 without lambda function ([#21](https://github.com/sonofagl1tch/AWSDetonationLab/pull/21)).

### Removed
* Removed unnecessary open ports and security group settings for Wazuh agents ([#38](https://github.com/sonofagl1tch/AWSDetonationLab/pull/38)).
* Removed installation of Python Pip in the Wazuh manager ([#57](https://github.com/sonofagl1tch/AWSDetonationLab/pull/57)).
