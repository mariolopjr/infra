{ westeros, ... }:
{
  westeros.host-profile =
    { host }:
    {
      includes = [
        (westeros.${host.name} or { })
        (westeros.host-name host)
        westeros.state-version
      ];
    };

  westeros.user-profile =
    { host, user }@ctx:
    {
      includes = [
        (westeros."${user.name}@${host.name}" or { })
        ((westeros.${host.name}._.common-user-env or (_: { })) ctx)
        ((westeros.${user.name}._.common-host-env or (_: { })) ctx)
      ];
    };
}
