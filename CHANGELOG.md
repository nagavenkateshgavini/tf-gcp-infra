Feb 13 2023:
- Create VPC with two subnets
- Auto-create subnets should be disabled during vpc creation
- Routing mode should be set to regional
- No default routes should be created
- The subnet has a /24 CIDR address range.
- Add a route to 0.0.0.0/0 for the webapp subnet. Do not add this for the db subnet
