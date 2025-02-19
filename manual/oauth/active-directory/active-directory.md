# Active Directory

## Install 

Install a Windows server ISO

Use this command to install the Active Directory Domain Services Role.

`Install-WindowsFeature AD-Domain-Services -IncludeManagementTools`

Then use this command to promote the server to a domain controller.

`Install-ADDSForest -DomainName "mylab.local" -CreateDnsDelegation:$false -DomainNetBiosName "mylab" -InstallDns:$true`

Enter a directory services restore password.

Reference:
https://activedirectorypro.com/create-active-directory-test-environment/#lesson-3

## Create users

Review the CSV files and ensure it meets the needs

Start PowerShell and run the following to allow unsigned code to run:

`Set-ExecutionPolicy Unrestricted`

Then run the 3 scripts:

```
create_ous.ps1
create_groups.ps1
create_users.ps1
```

Note that the PowerShell scripts do not put users in groups, this needs to be done manually.

## OpenShift Authentication

I have tested OpenShift LDAP integration for authentication adding the OID to the filter and it allows me to use nested groups for OpenShift authentication, for example in the OAuth config, specify the OID in the URL when specifying who can login:

`url: "ldap://ad:389/ou=MyLabUsers,dc=mylab,dc=local?sAMAccountName?sub?(&(objectClass=person)(memberOf:1.2.840.113556.1.4.1941:=CN=ocp_users,OU=MyLabGroups,DC=mylab,DC=local))"`

## OpenShift Group Sync

I was also able to sync nested groups out of my test AD LDAP into OpenShift.  

The LDAP sync config file (ConfigMap) needs to specify the OID in the group membership attributes field:

`groupMembershipAttributes: [ "memberOf:1.2.840.113556.1.4.1941:" ]`

And an allow list also needs to explicitly name the groups to sync:

```
$ cat allowlist.txt
CN=ocp_admins,OU=LabGroups,DC=mylab,DC=local
CN=Developers,OU=LabGroups,DC=mylab,DC=local
```

The first group is a top level group whose only members are 2 other groups.  The second group is a leaf level group with users as members.  

After running the LDAP sync command:

`oc adm groups sync --sync-config=ldap-sync-config.yaml --whitelist=allowlist.txt --confirm`

the result is 2 groups in OpenShift:

- ocp_admins: contains all users from the 2 nested groups in AD
- Developers: contains the users from the AD Developers group

This should be readily translatable into the cronjob.

## Quay Authentication

To get Quay to work with nested groups, and manage privilege levels:

```
    ...
    FEATURE_RESTRICTED_USERS: true
    ...
    LDAP_RESTRICTED_USER_FILTER: "(&(objectClass=person)(memberOf=CN=Management,OU=MyLabGroups,DC=mylab,DC=local))"
    LDAP_SUPERUSER_FILTER: "(&(objectClass=person)(memberOf:1.2.840.113556.1.4.1941:=CN=quay_admins,OU=MyLabGroups,DC=mylab,DC=local))"
    ...
    LDAP_USER_FILTER: "(&(objectClass=person)(memberOf:1.2.840.113556.1.4.1941:=CN=quay_users,OU=MyLabGroups,DC=mylab,DC=local))"
    LDAP_USER_RDN:
    - ou=MyLab Users
```

In my test AD, the group `CN=quay_users` is a 'Domain Local' that has only the 4 groups `CN=SysAdmin`, `CN=Operations`, `CN=Developers` and `CN=Management` as members. The group `CN=quay_admins` contains only the groups `CN=SysAdmin` and `CN=Operations`.

Those users in `CN=Management` can not create repositories or organisations.

Those users in `CN=SysAdmin` and `CN=Operations` show up in Quay as super users.

Adding the OID string '1.2.840.113556.1.4.1941' into the LDAP_USER_FILTER field as shown causes AD to flatten the groups. 

## Get the DN of an AD user

```powershell
Import-Module activedirectory
$userDetails = Get-ADUser SomeUserName -Properties someRandomAttribute
write-host $userDetails.someRandomAttribute
```
