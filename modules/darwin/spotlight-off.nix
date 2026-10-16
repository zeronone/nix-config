# Disable Spotlight indexing on all volumes (mds/mdworker churn is expensive under CrowdStrike Falcon).
# Spotlight still opens but finds little: apps, files and Mail search stop working.
# If this module is removed, run `sudo mdutil -a -i on` once to re-enable it.
{ ... }:
{
  system.activationScripts.postActivation.text = ''
    if /usr/bin/mdutil -a -s 2>/dev/null | grep -q "Indexing enabled"; then
      echo "disabling Spotlight indexing..."
      /usr/bin/mdutil -a -i off >/dev/null
    fi
  '';
}
