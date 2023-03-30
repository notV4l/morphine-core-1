
import { exec, spawn } from "child_process"
import Path from 'path'

const args = process.argv.slice(2);

const main = async () => {

    const filePath = args[0]

    const fileName = Path.basename(filePath)
    const targetName = fileName.replace('.cairo', '.json')

    // console.log(fileName)
    // console.log(targetName)

    const cargo = spawn(
        `cargo run --bin starknet-compile -- ${filePath} ../out/${targetName} --replace-ids`
        , { cwd: './cairo', shell: true, stdio: 'inherit' })

}


main()