# Migrate LDAP backend users to local (Database) users

```sh
occ maintenance:mode --on
occ app:disable user_ldap
```

SSO login with same username will automatically add an entry to `oc_users`. To not require first logins, rebuild it from `oc_accounts`.

Optionally:

```sql
DELETE FROM oc_preferences WHERE appid = 'user_ldap';
DELETE FROM oc_appconfig WHERE appid = 'user_ldap';
```

```sh
occ maintenance:mode --off
```

***

The steps assume you are ditching LDAP and migrating all. When not, ensure you don't have the same username on LDAP, as Nextcloud queries it for users (and may conflict with local user from `oc_users`).
