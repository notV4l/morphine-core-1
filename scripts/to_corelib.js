import fs from "fs"

const libs = [
    "oz",
    "anotherlib"
]

const libBasePath = "./src/lib"

const libSeparator = "// TEMPFIX"

const libDeclarations = libs.map(i => `\nmod ${i};`).join('')

const main = () => {

    // clean corelib
    for (let lib of libs) {
        try {
            fs.rmSync(`./cairo/corelib/src/${lib}`, { force: true, recursive: true })
        }
        catch (e) { }

        try {
            fs.rmSync(`./cairo/corelib/src/${lib}.cairo`)
        }
        catch (e) { }

    }

    // copy to corelib
    fs.cpSync(`${libBasePath}`, "./cairo/corelib/src", { recursive: true })

    //modify cairo/corelib/src/lib.cairo to import libs
    let content = fs.readFileSync('./cairo/corelib/src/lib.cairo')
    content = content.toString()

    // get original content
    content = content.split(libSeparator)[0]

    // add our libs
    content += `${libSeparator} ${libDeclarations}`

    // write lib.cairo
    fs.writeFileSync('./cairo/corelib/src/lib.cairo', content)


    console.log("\ncorelib updated !\n")


}





main()