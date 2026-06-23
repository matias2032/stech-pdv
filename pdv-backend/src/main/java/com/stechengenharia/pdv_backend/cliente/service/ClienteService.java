package com.stechengenharia.pdv_backend.cliente.service;

import com.stechengenharia.pdv_backend.cliente.dto.ClienteRequestDTO;
import com.stechengenharia.pdv_backend.cliente.dto.ClienteResponseDTO;
import com.stechengenharia.pdv_backend.cliente.entity.Cliente;
import com.stechengenharia.pdv_backend.cliente.entity.PerfilCliente;
import com.stechengenharia.pdv_backend.cliente.exception.ClienteNotFoundException;
import com.stechengenharia.pdv_backend.cliente.repository.ClienteRepository;
import com.stechengenharia.pdv_backend.cliente.repository.PerfilClienteRepository;
import lombok.RequiredArgsConstructor;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class ClienteService {

    private final ClienteRepository        clienteRepository;
    private final PerfilClienteRepository  perfilClienteRepository;

    // ── LISTAGEM ──────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<ClienteResponseDTO> listarTodos() {
        return clienteRepository.findAllComPerfil()
                .stream()
                .map(ClienteResponseDTO::new)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ClienteResponseDTO> listarPorPerfil(Long idPerfil) {
        return clienteRepository.findByPerfilId(idPerfil)
                .stream()
                .map(ClienteResponseDTO::new)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<ClienteResponseDTO> pesquisar(String termo) {
        if (termo == null || termo.isBlank()) return listarTodos();
        return clienteRepository.pesquisar(termo.trim())
                .stream()
                .map(ClienteResponseDTO::new)
                .toList();
    }

    // ── BUSCA POR ID ──────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public ClienteResponseDTO buscarPorId(Long id) {
        return new ClienteResponseDTO(encontrarOuLancar(id));
    }

    // ── CRIAÇÃO ───────────────────────────────────────────────────────

    @Transactional
public ClienteResponseDTO criar(ClienteRequestDTO dto) {
    validarUnicidadeCriacao(dto);
    PerfilCliente perfil = encontrarPerfilOuLancar(dto.idPerfil());

    Cliente novo = Cliente.builder()
            .nome(dto.nome())
            .apelido(dto.apelido())
            .email(dto.email())
            .nuit(dto.nuit())
            .contacto(dto.contacto())
            .morada(dto.morada())
            .perfil(perfil)
            .syncStatus("PENDING_CREATE")  // ← explícito (AuditableEntity já usa este default, mas deixa claro)
            .build();

    return new ClienteResponseDTO(clienteRepository.save(novo));
}

    // ── EDIÇÃO ────────────────────────────────────────────────────────

    @Transactional
    public ClienteResponseDTO editar(Long id, ClienteRequestDTO dto) {
        Cliente cliente = encontrarOuLancar(id);

        validarUnicidadeEdicao(id, dto);

        PerfilCliente perfil = encontrarPerfilOuLancar(dto.idPerfil());

        cliente.setNome(dto.nome());
        cliente.setApelido(dto.apelido());
        cliente.setEmail(dto.email());
        cliente.setNuit(dto.nuit());
        cliente.setContacto(dto.contacto());
        cliente.setMorada(dto.morada());
        cliente.setPerfil(perfil);

        return new ClienteResponseDTO(clienteRepository.save(cliente));
    }

// ── EXCLUSÃO FÍSICA SEGURA ─────────────────────────────────────────
@Transactional
public void excluir(Long id) {
    Cliente cliente = encontrarOuLancar(id);

    try {
        clienteRepository.delete(cliente);
        clienteRepository.flush();
    } catch (DataIntegrityViolationException e) {
        throw new IllegalStateException(
                "Não é possível excluir este cliente porque ele possui pedidos, documentos ou histórico associado."
        );
    }
}

// ── VALIDAÇÕES PRIVADAS ───────────────────────────────────────────
private void validarUnicidadeCriacao(ClienteRequestDTO dto) {
    if (dto.email() != null && !dto.email().isBlank()
            && clienteRepository.existsByEmailAndDeletedFalse(dto.email())) {
        throw new IllegalArgumentException("Já existe um cliente com este e-mail.");
    }
    if (dto.nuit() != null && !dto.nuit().isBlank()
            && clienteRepository.existsByNuitAndDeletedFalse(dto.nuit())) {
        throw new IllegalArgumentException("Já existe um cliente com este NUIT.");
    }
    if (dto.contacto() != null && !dto.contacto().isBlank()
            && clienteRepository.existsByContactoAndDeletedFalse(dto.contacto())) {
        throw new IllegalArgumentException("Já existe um cliente com este contacto.");
    }
}

private void validarUnicidadeEdicao(Long id, ClienteRequestDTO dto) {
    if (dto.email() != null && !dto.email().isBlank()
            && clienteRepository.existsByEmailAndIdNotAndDeletedFalse(dto.email(), id)) {
        throw new IllegalArgumentException("Já existe um cliente com este e-mail.");
    }
    if (dto.nuit() != null && !dto.nuit().isBlank()
            && clienteRepository.existsByNuitAndIdNotAndDeletedFalse(dto.nuit(), id)) {
        throw new IllegalArgumentException("Já existe um cliente com este NUIT.");
    }
    if (dto.contacto() != null && !dto.contacto().isBlank()
            && clienteRepository.existsByContactoAndIdNotAndDeletedFalse(dto.contacto(), id)) {
        throw new IllegalArgumentException("Já existe um cliente com este contacto.");
    }
}

    // ── HELPERS ───────────────────────────────────────────────────────

    private Cliente encontrarOuLancar(Long id) {
        return clienteRepository.findByIdComPerfil(id)
                .orElseThrow(() -> new ClienteNotFoundException(id));
    }

    private PerfilCliente encontrarPerfilOuLancar(Long idPerfil) {
        return perfilClienteRepository.findById(idPerfil)
                .orElseThrow(() -> new IllegalArgumentException(
                        "Perfil de cliente não encontrado com o ID: " + idPerfil));
    }
}