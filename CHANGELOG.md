# Changelog

## v3.0.0

* New image based on Bullseye
* SASLAUTHD_LDAP_FILTER has a __breaking change__, if the domain is used
  you will need to change this to: "%u@%r"

## v2.2.0

* Do not use the backport version of prosody, this is broken with sasl
  * https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=914536
  * https://issues.prosody.im/1256
  * https://prosody.im/doc/release/0.11.0#lua-5.2

## v2.1.0

* Import repo and update labels
