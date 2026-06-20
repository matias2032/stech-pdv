package com.stechengenharia.pdv_backend.fornecedor.service;

import com.stechengenharia.pdv_backend.fornecedor.dto.FornecedorRequestDTO;
import com.stechengenharia.pdv_backend.fornecedor.dto.FornecedorResponseDTO;
import com.stechengenharia.pdv_backend.fornecedor.entity.Fornecedor;
import com.stechengenharia.pdv_backend.fornecedor.exception.FornecedorNotFoundException;
import com.stechengenharia.pdv_backend.fornecedor.repository.FornecedorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class FornecedorService {

    private final FornecedorRepository fornecedorRepository;

    // ── LISTAGEM ─────────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public List<FornecedorResponseDTO> listarTodos() {
        return fornecedorRepository.findAllAtivos()
                .stream()
                .map(FornecedorResponseDTO::new)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<FornecedorResponseDTO> pesquisar(String termo) {
        if (termo == null || termo.isBlank()) {
            return listarTodos();
        }

        return fornecedorRepository.pesquisar(termo.trim())
                .stream()
                .map(FornecedorResponseDTO::new)
                .toList();
    }

    // ── BUSCA POR ID ─────────────────────────────────────────────────

    @Transactional(readOnly = true)
    public FornecedorResponseDTO buscarPorId(Long id) {
        return new FornecedorResponseDTO(encontrarOuLancar(id));
    }

    // ── CRIAÇÃO ──────────────────────────────────────────────────────

    @Transactional
    public FornecedorResponseDTO criar(FornecedorRequestDTO dto) {
        validarContactoObrigatorio(dto);
        validarUnicidadeCriacao(dto);

        Fornecedor fornecedor = Fornecedor.builder()
                .nome(dto.nome())
                .email(dto.email())
                .nuit(dto.nuit())
                .contacto(dto.contacto().trim())
                .morada(dto.morada())
                .syncStatus("PENDING_CREATE")
                .build();

        return new FornecedorResponseDTO(fornecedorRepository.save(fornecedor));
    }

    // ── EDIÇÃO ───────────────────────────────────────────────────────

    @Transactional
    public FornecedorResponseDTO editar(Long id, FornecedorRequestDTO dto) {
        validarContactoObrigatorio(dto);

        Fornecedor fornecedor = encontrarOuLancar(id);

        validarUnicidadeEdicao(id, dto);

        fornecedor.setNome(dto.nome());
        fornecedor.setEmail(dto.email());
        fornecedor.setNuit(dto.nuit());
        fornecedor.setContacto(dto.contacto().trim());
        fornecedor.setMorada(dto.morada());

        return new FornecedorResponseDTO(fornecedorRepository.save(fornecedor));
    }

    // ── EXCLUSÃO SOFT DELETE ─────────────────────────────────────────

    @Transactional
    public void excluir(Long id) {
        Fornecedor fornecedor = encontrarOuLancar(id);
        fornecedor.setDeleted(true);
        fornecedor.setSyncStatus("PENDING_DELETE");
        fornecedorRepository.save(fornecedor);
    }

    // ── VALIDAÇÕES ───────────────────────────────────────────────────

    private void validarContactoObrigatorio(FornecedorRequestDTO dto) {
        if (dto.contacto() == null || dto.contacto().isBlank()) {
            throw new IllegalArgumentException("Contacto é obrigatório.");
        }
    }

    private void validarUnicidadeCriacao(FornecedorRequestDTO dto) {
        if (dto.email() != null && !dto.email().isBlank()
                && fornecedorRepository.existsByEmailAndDeletedFalse(dto.email())) {
            throw new IllegalArgumentException("Já existe um fornecedor com este e-mail.");
        }

        if (dto.nuit() != null && !dto.nuit().isBlank()
                && fornecedorRepository.existsByNuitAndDeletedFalse(dto.nuit())) {
            throw new IllegalArgumentException("Já existe um fornecedor com este NUIT.");
        }

        if (dto.contacto() != null && !dto.contacto().isBlank()
                && fornecedorRepository.existsByContactoAndDeletedFalse(dto.contacto())) {
            throw new IllegalArgumentException("Já existe um fornecedor com este contacto.");
        }
    }

    private void validarUnicidadeEdicao(Long id, FornecedorRequestDTO dto) {
        if (dto.email() != null && !dto.email().isBlank()
                && fornecedorRepository.existsByEmailAndIdNotAndDeletedFalse(dto.email(), id)) {
            throw new IllegalArgumentException("Já existe um fornecedor com este e-mail.");
        }

        if (dto.nuit() != null && !dto.nuit().isBlank()
                && fornecedorRepository.existsByNuitAndIdNotAndDeletedFalse(dto.nuit(), id)) {
            throw new IllegalArgumentException("Já existe um fornecedor com este NUIT.");
        }

        if (dto.contacto() != null && !dto.contacto().isBlank()
                && fornecedorRepository.existsByContactoAndIdNotAndDeletedFalse(dto.contacto(), id)) {
            throw new IllegalArgumentException("Já existe um fornecedor com este contacto.");
        }
    }

    // ── HELPERS ──────────────────────────────────────────────────────

    private Fornecedor encontrarOuLancar(Long id) {
        return fornecedorRepository.findByIdAtivo(id)
                .orElseThrow(() -> new FornecedorNotFoundException(id));
    }
}