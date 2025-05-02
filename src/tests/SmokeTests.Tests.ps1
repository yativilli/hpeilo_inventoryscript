BeforeAll{
    $serversUsedForTesting = @(
        "rmgfa-sioc-cs-dev",
        "rmgfa-sioc-cs-de3",
        "rmgfa-sioc-cs-de4",
        "rmdl20test"
    )

    $inventory = "inventory.psi.ch";
}

Describe "TestServers" {
    it "all servers should be reachable via nslookup"{
        $serverNotReachable = $false;
        foreach($srv in $serversUsedForTesting){
            try{
                Resolve-DnsName $srv;
            }catch{
                $serverNotReachable = $true;
            }
        }
        $serverNotReachable | Should -Not -Be $true;
    }

    it "all servers should be reachable via test-connection"{
        $serverNotReachable = $false;
        foreach($srv in $serversUsedForTesting){
            try{
                Test-Connection $srv - -Quiet -Count 1;
            }catch{
                Write-Host $srv;
                $serverNotReachable = $true;
            }
        }
        $serverNotReachable | Should -Not -Be $true;
    }
}

Describe "Inventory Reachable"{
    it " inventory is reachable"{
        $inventoryDNSNotFound = $false;
        try{
            Resolve-DnsName $inventory
        }catch{
            $inventoryDNSNotFound = $true;
        }
        $connectionSuccessfull = Test-Connection $inventory -Quiet -Count 1;

        $inventoryDNSNotFound | Should -Not -Be $true;
        $connectionSuccessfull | Should -Be $true;
    }
}