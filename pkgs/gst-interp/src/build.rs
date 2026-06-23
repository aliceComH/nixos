//! build.rs — compila os shaders GLSL para SPIR-V em tempo de build.
//!
//! Invoca o binário `glslang` (fornecido pelo nativeBuildInput no package.nix
//! via a variável de ambiente GLSLANG_VALIDATOR).
//!
//! Os arquivos .spv resultantes são colocados em OUT_DIR e incluídos no binário
//! via `include_bytes!` em compute.rs.

use std::{
    env,
    path::PathBuf,
    process::Command,
};

fn main() {
    // Localiza o binário glslang. No NixOS o nativeBuildInput seta GLSLANG_VALIDATOR.
    // Fora do Nix (dev local), tenta o PATH como fallback.
    let glslang = env::var("GLSLANG_VALIDATOR")
        .unwrap_or_else(|_| "glslang".to_string());

    let out_dir = PathBuf::from(env::var("OUT_DIR").expect("OUT_DIR não definido"));

    // Lista de shaders a compilar: (fonte, saída)
    let shaders: &[(&str, &str)] = &[
        ("shaders/interpolate.comp", "interpolate.comp.spv"),
    ];

    for (src, dst) in shaders {
        let src_path = PathBuf::from(src);
        let dst_path = out_dir.join(dst);

        // Notifica cargo para re-compilar se o shader mudar
        println!("cargo:rerun-if-changed={src}");

        compile_shader(&glslang, &src_path, &dst_path);
    }

    // Expõe OUT_DIR para os módulos Rust via env!("OUT_DIR")
    // (já funciona automaticamente, mas documentamos aqui por clareza)
}

/// Compila um arquivo GLSL para SPIR-V usando glslang.
///
/// Flags usadas:
/// - `-V`                     → gera SPIR-V
/// - `--target-env vulkan1.2` → target Vulkan 1.2 (suportado pela RX 9070 / radv)
/// - `-o <dst>`               → arquivo de saída .spv
fn compile_shader(glslang_bin: &str, src: &PathBuf, dst: &PathBuf) {
    let status = Command::new(glslang_bin)
        .args([
            "-V",
            "--target-env", "vulkan1.2",
            "-o", dst.to_str().expect("caminho inválido"),
            src.to_str().expect("caminho inválido"),
        ])
        .status()
        .unwrap_or_else(|e| {
            panic!(
                "Falha ao invocar glslang ({glslang_bin}): {e}\n\
                 Certifique-se de que glslang está no PATH ou defina GLSLANG_VALIDATOR."
            )
        });

    if !status.success() {
        panic!(
            "Compilação do shader falhou: {} → {}\nVerifique os erros GLSL acima.",
            src.display(),
            dst.display()
        );
    }

    println!("cargo:warning=✅ Shader compilado: {} → {}", src.display(), dst.display());
}
