# Nix showcase: a flake with packages, shells, overlays and the expression language.
# TODO: add a NixOS module output
/* A block comment
   over several lines. */
{
  description = "Inventory service: dev shell and package";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    local.url = "path:./vendor";
    legacy = { url = "git+https://example.com/legacy.git?ref=main"; flake = false; };
    follows.inputs.nixpkgs.follows = "nixpkgs";
  };

  nixConfig = {
    extra-substituters = [ "https://cache.example.com" ];
    bash-prompt = "\\[inventory\\] ";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # ── Literals ──
        pkgs = import nixpkgs { inherit system; overlays = [ self.overlays.default ]; };
        inherit (pkgs) lib stdenv;
        version = "1.4.0";
        integer = 42;
        negative = -7;
        float = 3.14;
        exponent = 1.5e-3;
        truthy = true;
        falsy = false;
        nothing = null;
        absPath = /etc/nix/nix.conf;
        relPath = ./src/main.c;
        parentPath = ../shared;
        homePath = ~/projects;
        nixPath = <nixpkgs>;
        nixSub = <nixpkgs/lib>;
        uri = https://example.com/archive.tar.gz;
        simple = "double quoted with escapes: \n \t \" \\ \${not interpolated}";
        interpolated = "inventory-${version}-${toString integer}";
        nested = "outer ${lib.concatStringsSep ", " [ "a" "b" "${version}" ]} done";
        indented = ''
          An indented string, with ${version} interpolated
          and ''${escaped} dollars, ''\n escapes and ''' quotes.
            Indentation is stripped.
        '';
        list = [ 1 2.5 "three" ./four (five) [ 6 ] { seven = 7; } ];
        attrs = { a = 1; b.c.d = 2; "quoted key" = 3; ${"dyn" + "amic"} = 4; };
        recAttrs = rec { x = 1; y = x + 1; };

        # ── Functions ──
        add = a: b: a + b;
        pattern = { name, age ? 30, ... }: "${name} is ${toString age}";
        bound = args@{ x, y, ... }: x + y + args.z;
        trailing = { x, y }@all: all;
        curried = lib.mapAttrs (n: v: v * 2) { one = 1; two = 2; };
        compose = f: g: x: f (g x);
        applied = add 1 2;
        piped = 5 |> (x: x + 1);

        # ── Operators ──
        arithmetic = (1 + 2 - 3) * 4 / 2;
        comparison = 1 < 2 && 2 <= 2 || 3 > 4 && 4 >= 5;
        equality = 1 == 1 && 2 != 3;
        negation = !truthy;
        implication = truthy -> falsy;
        listConcat = [ 1 ] ++ [ 2 ];
        attrUpdate = { a = 1; } // { b = 2; };
        hasAttr = attrs ? a;
        hasPath = attrs ? b.c.d;
        selectOr = attrs.missing or "default";
        selected = attrs.b.c.d;
        stringConcat = "a" + "b";
        pathConcat = ./. + "/file";

        # ── Control flow ──
        conditional = if integer > 40 then "big" else "small";
        withExpr = with lib; concatStringsSep "-" [ "a" "b" ];
        assertion = assert integer == 42; "ok";
        letIn = let a = 1; b = 2; in a + b;
        builtinCalls = builtins.map (x: x * 2) [ 1 2 3 ];
        fromJson = builtins.fromJSON ''{"k": [1, 2, null, true]}'';
        throwing = if falsy then throw "never" else abort "unused";
      in {
        packages.default = stdenv.mkDerivation {
          pname = "inventory";
          inherit version;
          src = ./.;
          nativeBuildInputs = [ pkgs.pkg-config ];
          buildInputs = [ pkgs.sqlite ] ++ lib.optionals stdenv.isDarwin [ pkgs.libiconv ];
          buildPhase = "cc -O2 -o inventory src/*.c -lsqlite3";
          installPhase = ''
            mkdir -p $out/bin
            cp inventory $out/bin/
          '';
          postInstall = lib.optionalString stdenv.isLinux ''
            wrapProgram $out/bin/inventory --set VERSION ${version}
          '';
          doCheck = true;
          passthru = { inherit pkgs; tests = { }; };
          meta = with lib; {
            description = "Stock levels and reorder checks";
            license = licenses.mit;
            platforms = platforms.unix;
            maintainers = [ ];
          };
        };

        apps.default = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/inventory";
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [ sqlite gnumake clang-tools ];
          shellHook = "echo 'inventory ${version} dev shell'";
          INVENTORY_DB = ":memory:";
        };

        formatter = pkgs.nixpkgs-fmt;
        checks.build = self.packages.${system}.default;
        legacyPackages = import ./default.nix { inherit pkgs; };
      }) // {
        overlays.default = final: prev: {
          inventory = final.callPackage ./package.nix { };
        };
        nixosModules.default = { config, lib, pkgs, ... }: {
          options.services.inventory.enable = lib.mkEnableOption "the inventory service";
          options.services.inventory.port = lib.mkOption {
            type = lib.types.port;
            default = 8080;
            description = "Listening port.";
          };
          config = lib.mkIf config.services.inventory.enable {
            systemd.services.inventory = {
              wantedBy = [ "multi-user.target" ];
              serviceConfig.ExecStart = "${pkgs.inventory}/bin/inventory --port ${toString config.services.inventory.port}";
            };
          };
        };
      };
}

# ── Standalone expression forms (a second file would normally hold these) ──
# let
#   inherit (builtins) map filter;
#   inherit ({ a = 1; b = 2; }) a b;
#   x = 5;
#   fix = f: let result = f result; in result;
# in
# rec {
#   pathInterp = ./src/${toString x}/file.nix;
#   dynamicAttr.${"key"} = 1;
#   strAttr."a-b".c = 2;
#   curriedCall = builtins.foldl' (acc: v: acc + v) 0 [ 1 2 3 ];
#   floatMath = 1.5 * 2.0 - 0.5 / 0.25;
#   cmp = 1 < 2 && 2 >= 1 || !(3 == 4);
#   isNull = builtins.isNull null;
#   trace = builtins.trace "msg" x;
#   toJSON = builtins.toJSON { a = [ 1 2 ]; };
#   fetch = builtins.fetchurl "https://example.com/file";
#   readDir = builtins.readDir ./.;
#   match = builtins.match "(a)(b)" "ab";
#   split = builtins.split "," "a,b";
#   sub = builtins.substring 0 3 "abcdef";
#   len = builtins.stringLength "abc";
#   hash = builtins.hashString "sha256" "x";
#   path = builtins.path { path = ./.; name = "src"; };
#   currentSystem = builtins.currentSystem;
#   nixVersion = builtins.nixVersion;
#   langVersion = builtins.langVersion;
#   unsafeDiscard = builtins.unsafeDiscardStringContext "x";
#   functor = { __functor = self: arg: arg + 1; };
#   outPath = { outPath = "/nix/store/example"; };
#   mergeable = { a.b = 1; a.c = 2; };
#   emptySet = { };
#   emptyList = [ ];
#   nestedInterp = "a${"b${"c"}"}d";
#   escapes = "\r \\ \" \${ $ $$";
#   indentedEsc = '' ''$ ''\t ''' ${"x"} '';
#   lambdaPat = { a, b ? { c = 1; }, ... }@args: a;
#   uri2 = http://example.com/path?query=1#frag;
#   path2 = a/b/c.nix;
#   absolutePath = /nix/store;
#   searchPath = <nixpkgs/nixos>;
#   negNumber = -5 + - 3;
#   with_ = with builtins; length [ 1 2 3 ];
#   assert_ = assert true; "yes";
#   ifChain = if x == 1 then "one" else if x == 2 then "two" else "many";
#   letNested = let a = let b = 1; in b; in a;
#   pipeOp = 5 |> (n: n * 2);
#   backPipe = (n: n * 2) <| 5;
# }
