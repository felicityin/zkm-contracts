use anyhow::Result;
use zkm_sdk::install::try_install_circuit_artifacts;
use zkm_sdk::utils::setup_logger;
use zkm_sdk::ZKM_CIRCUIT_VERSION;
use std::fs::{create_dir_all, read, read_dir, write};
use std::path::PathBuf;

fn main() -> Result<()> {
    dotenv::dotenv().ok();

    setup_logger();

    let artifact_types = ["plonk", "groth16"];
    let mut artifact_dirs = Vec::new();

    for &artifact_type in &artifact_types {
        let artifacts_dir = try_install_circuit_artifacts(artifact_type);
        artifact_dirs.push(artifacts_dir);
    }

    // Read all Solidity files from the artifacts directories.
    let contracts_src_dir = PathBuf::from(format!("contracts/src/{}", ZKM_CIRCUIT_VERSION));
    create_dir_all(&contracts_src_dir)?;

    for artifacts_dir in artifact_dirs {
        let sol_files = read_dir(artifacts_dir)?
            .filter_map(|entry| entry.ok())
            .filter(|entry| entry.path().extension().and_then(|ext| ext.to_str()) == Some("sol"))
            .collect::<Vec<_>>();

        // Write each Solidity file to the contracts directory.
        for sol_file in sol_files {
            let sol_file_path = sol_file.path();
            let sol_file_contents = read(&sol_file_path)?;
            write(
                contracts_src_dir.join(sol_file_path.file_name().unwrap()),
                sol_file_contents,
            )?;
        }
    }

    println!(
        "Added the new verifier contracts to {}",
        contracts_src_dir.display()
    );

    // Copy deployment scripts from v1.0.0 to {ZKM_CIRCUIT_VERSION}
    let source_deploy_dir = PathBuf::from("contracts/script/deploy/v1.0.0");
    let target_deploy_dir = PathBuf::from(format!("contracts/script/deploy/{}", ZKM_CIRCUIT_VERSION));
    create_dir_all(&target_deploy_dir)?;

    for entry in read_dir(source_deploy_dir)? {
        let entry = entry?;
        let source_path = entry.path();
        if source_path.is_file() {
            let file_name = source_path.file_name().unwrap();
            let target_path = target_deploy_dir.join(file_name);
            std::fs::copy(&source_path, &target_path)?;

            // Modify ZKMVerifierGroth16.s.sol
            if file_name == "ZKMVerifierGroth16.s.sol" {
                let mut content = String::from_utf8(read(&target_path)?)?;
                content = content.replace(
                    "import {ZKMVerifier} from \"../../../src/v1.0.0/ZKMVerifierGroth16.sol\";",
                    &format!("import {{ZKMVerifier}} from \"../../../src/{}/ZKMVerifierGroth16.sol\";", ZKM_CIRCUIT_VERSION)
                );
                content = content.replace(
                    "string internal constant KEY = \"V1_0_0_ZKM_VERIFIER_GROTH16\";",
                    &format!("string internal constant KEY = \"{}_ZKM_VERIFIER_GROTH16\";", ZKM_CIRCUIT_VERSION.replace(".", "_").replace("-", "_").to_uppercase())
                );
                write(&target_path, content)?;
            }

            // Modify ZKMVerifierPlonk.s.sol
            if file_name == "ZKMVerifierPlonk.s.sol" {
                let mut content = String::from_utf8(read(&target_path)?)?;
                content = content.replace(
                    "import {ZKMVerifier} from \"../../../src/v1.0.0/ZKMVerifierPlonk.sol\";",
                    &format!("import {{ZKMVerifier}} from \"../../../src/{}/ZKMVerifierPlonk.sol\";", ZKM_CIRCUIT_VERSION)
                );
                content = content.replace(
                    "string internal constant KEY = \"V1_0_0_ZKM_VERIFIER_PLONK\";",
                    &format!("string internal constant KEY = \"{}_ZKM_VERIFIER_PLONK\";", ZKM_CIRCUIT_VERSION.replace(".", "_").replace("-", "_").to_uppercase())
                );
                write(&target_path, content)?;
            }
        }
    }

    println!(
        "Copied and updated deployment scripts to {}",
        target_deploy_dir.display()
    );

    Ok(())
}
