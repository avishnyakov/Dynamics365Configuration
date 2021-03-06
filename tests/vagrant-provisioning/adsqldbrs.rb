Vagrant.configure(2) do |config|
    config.vm.provision :shell, path: "../../../../infrastructure/images/basepsmodules.ps1"
    config.vm.provision :shell, path: "../../../../infrastructure/images/adpsmodules.ps1"
    config.vm.provision :shell, path: "../../../../infrastructure/stacks/domain.ps1", env: {"SPDEVOPSSTARTER_NODSCTEST" => "TRUE"}
    config.vm.provision "reload"
    config.vm.provision :shell, path: "../../../../infrastructure/stacks/domain.ps1"
    config.vm.provision :shell, path: "../../../../infrastructure/stacks/crmdomaincustomizations.ps1"
    config.vm.provision :shell, path: "../../../../infrastructure/stacks/crmdomainlocalinstall.ps1"
    config.vm.provision :shell, path: "../../../../infrastructure/stacks/xcredclient.ps1"
    config.vm.provision "reload"
    config.vm.provision :shell, path: "../../../../infrastructure/stacks/dbservernamefix.ps1"
    config.vm.provision :shell, path: "../../../../infrastructure/stacks/sqlconfig.ps1"
    config.vm.provision :shell, path: "../../../../infrastructure/stacks/rsconfig.ps1"
    config.vm.provision :shell, path: "../../../../infrastructure/stacks/rsserviceaccountupdate.ps1"
    config.vm.provision :file, source: "../../../../src", destination: "c:/tmp/Dynamics365Configuration/src"
    config.vm.provision :shell, inline: "powershell -command 'Import-Module c:/tmp/Dynamics365Configuration/src/Dynamics365Configuration/RootModule.psm1; Install-Dynamics365Prerequisite;'"
    config.vm.provision "reload"
    config.vm.provision :shell, inline: "powershell -command 'Remove-ItemProperty -Path HKLM:\\\\Software\\Microsoft\\Windows\\CurrentVersion\\RunOnce -Name ASYNCMAC -ErrorAction Ignore'"
end