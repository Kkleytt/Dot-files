{ pkgs, pkgsUnstable, ... }:

let upkgs = if pkgsUnstable == null then pkgs else pkgsUnstable; in

{
  environment.systemPackages = (with upkgs; [
    taskbook                                      # TUI менеджер задач 
    timr-tui                                      # TUI универсальный таймер
  ]);
}