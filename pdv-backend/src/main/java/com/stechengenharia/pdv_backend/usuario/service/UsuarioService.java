package com.stechengenharia.pdv_backend.usuario.service;

import com.stechengenharia.pdv_backend.usuario.dto.LoginRequestDTO;
import com.stechengenharia.pdv_backend.usuario.dto.UsuarioRequestDTO;
import com.stechengenharia.pdv_backend.usuario.dto.UsuarioResponseDTO;
import com.stechengenharia.pdv_backend.usuario.entity.HistoricoSenhas;
import com.stechengenharia.pdv_backend.usuario.entity.Perfil;
import com.stechengenharia.pdv_backend.usuario.entity.Usuario;
import com.stechengenharia.pdv_backend.usuario.exception.UsuarioNotFoundException;
import com.stechengenharia.pdv_backend.usuario.repository.HistoricoSenhasRepository;
import com.stechengenharia.pdv_backend.usuario.repository.PerfilRepository;
import com.stechengenharia.pdv_backend.usuario.repository.UsuarioRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
@RequiredArgsConstructor
public class UsuarioService {

    private static final String SENHA_PADRAO = "12345678";
    private static final List<Long> PERFIS_VISIVEIS = List.of(2L, 3L);

    private final UsuarioRepository         usuarioRepository;
    private final PerfilRepository          perfilRepository;
    private final HistoricoSenhasRepository historicoSenhasRepository;
    private final PasswordEncoder           passwordEncoder;

    // ── LISTAGEM ──────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<UsuarioResponseDTO> listarTodos() {
        return usuarioRepository.findByPerfilIds(PERFIS_VISIVEIS)
                .stream().map(UsuarioResponseDTO::new).toList();
    }

    @Transactional(readOnly = true)
    public List<UsuarioResponseDTO> listarPorStatus(Boolean ativo) {
        if (ativo == null) return listarTodos();
        return usuarioRepository.findByPerfilIdsAndAtivo(PERFIS_VISIVEIS, ativo)
                .stream().map(UsuarioResponseDTO::new).toList();
    }

    @Transactional(readOnly = true)
    public UsuarioResponseDTO buscarPorId(Long id) {
        return new UsuarioResponseDTO(encontrarOuLancar(id));
    }

    // ── CRIAÇÃO ───────────────────────────────────────────────────────

    @Transactional
    public UsuarioResponseDTO salvar(UsuarioRequestDTO dto) {
        if (usuarioRepository.existsByEmail(dto.email())) {
            throw new IllegalArgumentException("Este e-mail já está cadastrado.");
        }

        Perfil perfil = perfilRepository.findById(dto.idPerfil())
                .orElseThrow(() -> new UsuarioNotFoundException(
                        "Perfil não encontrado com o ID: " + dto.idPerfil()));

        String senhaRaw = (dto.senha() != null && !dto.senha().isBlank())
                ? dto.senha() : SENHA_PADRAO;

        Usuario novo = Usuario.builder()
                .nome(dto.nome())
                .apelido(dto.apelido())
                .email(dto.email())
                .telefone(dto.telefone())
                .senhaHash(passwordEncoder.encode(senhaRaw))
                .ativo(true)
                .primeiraSenha(true)
                .perfil(perfil)
                .build();

        // ← MUDANÇA: marca explicitamente para sincronização
        novo.setSyncStatus("PENDING_CREATE");

        return new UsuarioResponseDTO(usuarioRepository.save(novo));
    }

    // ── SOFT DELETE ───────────────────────────────────────────────────

    /**
     * Eliminação lógica. Nunca apaga fisicamente.
     * O motor de sync irá ler PENDING_DELETE e propagar a deleção para a nuvem.
     */
    @Transactional
    public void eliminar(Long id) {
        Usuario usuario = encontrarOuLancar(id);
        usuario.setDeleted(true);
        usuario.setSyncStatus("PENDING_DELETE");
        usuarioRepository.save(usuario);
        // @PreUpdate do AuditableEntity atualiza updated_at automaticamente
    }

    // ── TOGGLE ATIVO ──────────────────────────────────────────────────

    @Transactional
    public UsuarioResponseDTO toggleAtivo(Long id) {
        Usuario usuario = encontrarOuLancar(id);
        usuario.setAtivo(!usuario.getAtivo());
        // @PreUpdate → sync_status = PENDING_UPDATE automaticamente
        return new UsuarioResponseDTO(usuarioRepository.save(usuario));
    }

    // ── SENHAS ────────────────────────────────────────────────────────

    @Transactional
    public void resetarSenha(Long id) {
        Usuario usuario = encontrarOuLancar(id);
        guardarHistorico(usuario);
        usuario.setSenhaHash(passwordEncoder.encode(SENHA_PADRAO));
        usuario.setPrimeiraSenha(true);
        usuarioRepository.save(usuario);
    }

    @Transactional
    public void alterarSenha(Long id, String senhaAtual, String novaSenha) {
        Usuario usuario = encontrarOuLancar(id);
        if (!passwordEncoder.matches(senhaAtual, usuario.getSenhaHash())) {
            throw new IllegalArgumentException("Senha actual incorrecta.");
        }
        guardarHistorico(usuario);
        usuario.setSenhaHash(passwordEncoder.encode(novaSenha));
        usuario.setPrimeiraSenha(false);
        usuarioRepository.save(usuario);
    }

    // ── AUTH ──────────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public Usuario autenticar(LoginRequestDTO dto) {
        Usuario usuario = usuarioRepository.findByCredencial(dto.credencial())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED, "Credencial ou senha incorretos."));

        if (!usuario.getAtivo()) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Conta inactiva. Contacte o administrador.");
        }
        if (!passwordEncoder.matches(dto.senha(), usuario.getSenhaHash())) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED, "Credencial ou senha incorretos.");
        }
        return usuario;
    }

    @Transactional
    public void trocarPrimeiraSenha(Long id, String novaSenha) {
        Usuario usuario = encontrarOuLancar(id);
        guardarHistorico(usuario);
        usuario.setSenhaHash(passwordEncoder.encode(novaSenha));
        usuario.setPrimeiraSenha(false);
        usuarioRepository.save(usuario);
    }

    // ── HELPERS PRIVADOS ──────────────────────────────────────────────

    /**
     * Usa findByIdComPerfil para garantir que deleted=false é respeitado
     * e que o perfil já vem carregado (evita N+1).
     */
    private Usuario encontrarOuLancar(Long id) {
        return usuarioRepository.findByIdComPerfil(id)
                .orElseThrow(() -> new UsuarioNotFoundException(
                        "Usuário não encontrado com o ID: " + id));
    }

    private void guardarHistorico(Usuario usuario) {
        HistoricoSenhas h = new HistoricoSenhas();
        h.setUsuario(usuario);
        h.setSenhaHash(usuario.getSenhaHash());
        historicoSenhasRepository.save(h);
    }
}