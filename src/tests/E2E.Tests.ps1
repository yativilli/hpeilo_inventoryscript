BeforeAll {
    Remove-Module ILO-Inventorizer
    
    Import-Module .\ILO-Inventorizer\ILO-Inventorizer.psm1 -Force;
    Import-Module HPEiLOCmdlets

    $configPath = $ENV:TEMP + "\hpeilo_test";
    if ((Test-Path $configPath)) {
        Remove-Item $configPath -Recurse -Force;
    }
    New-Item -ItemType Directory $configPath -Force;
}

Describe "End2EndTests" {
    BeforeEach {
        if (Test-Path $configPath) {
            Remove-Item $configPath -Recurse -Force;
        }
        Set-ConfigPath -Reset;
    }
    Context "Regular" {
        it "should work without any parameters and without config specified" {
            # Arrange

            # Act

            # Assert
        }

        it "should work with configpath" {
            # Arrange

            # Act

            # Assert
        }

        it "should work with searchstring" {
            # Arrange

            # Act

            # Assert
        }

        it "should work with serverpath" {
            # Arrange

            # Act

            # Assert
        }

        it "should work with serverarray" {
            # Arrange

            # Act

            # Assert
        }
    }

    Context "Scanner" {
        it "should work with scanner" {
            # Arrange

            # Act

            # Assert
        }
    }
}

AfterAll {
    Remove-Item -Path ($ENV:TEMP + "\hpeilo_test") -Force -Recurse;
}