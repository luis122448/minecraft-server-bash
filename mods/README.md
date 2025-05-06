# Adding Mods to your Forge Server

To install mods, copy your mod files (`.jar` files) directly into the `./mods` directory located in your Minecraft Forge server's main folder.

```bash
# Place your .jar files here
./mods/
```

**⚠️ IMPORTANT!** Ensure each mod's version is compatible with the specific Minecraft and Forge version your server is running. Incompatible mods can cause server startup failures or in-game issues.

**Example `./mods` Directory Content:**

```bash
    tree ./mods

    ./mods
    ├── alexsmobs-1.22.8.jar
    ├── citadel-2.5.4-1.20.1.jar
    ├── Xaeros_Minimap_24.5.0_Forge_1.20.jar
    ├── XaerosWorldMap_1.39.0_Forge_1.20.jar
    └── ...
```