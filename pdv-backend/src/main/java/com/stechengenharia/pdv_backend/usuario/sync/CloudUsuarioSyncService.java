package com.stechengenharia.pdv_backend.usuario.sync;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class CloudUsuarioSyncService {

    private final CloudUsuarioRepository cloudUsuarioRepository;

    /**
     * Upsert: se o registo existe e a versão recebida é maior, actualiza.
     * Se não existe, cria. Operação idempotente — re-envios são seguros.
     */
    @Transactional
    public void processarPush(List<UsuarioSyncDTO> payload) {
        for (UsuarioSyncDTO dto : payload) {
            cloudUsuarioRepository.findByLocalId(dto.localId()).ifPresentOrElse(
                existente -> {
                    if (dto.version() > existente.getVersion()) {
                        existente.setNome(dto.nome());
                        existente.setApelido(dto.apelido());
                        existente.setSenhaHash(dto.senhaHash());
                        existente.setAtivo(dto.ativo());
                        existente.setDeleted(dto.deleted());
                        existente.setVersion(dto.version());
                        existente.setUpdatedAt(dto.updatedAt());
                        cloudUsuarioRepository.save(existente);
                    }
                    // Se version <= existente.version → ignorar (idempotência)
                },
                () -> {
                    // Registo novo na nuvem
                    CloudUsuarioEntity novo = CloudUsuarioEntity.fromSyncDTO(dto);
                    cloudUsuarioRepository.save(novo);
                }
            );
        }
    }

    @Transactional(readOnly = true)
    public List<UsuarioSyncDTO> buscarAtualizadosDesde(OffsetDateTime since) {
        return cloudUsuarioRepository.findByUpdatedAtAfter(since)
                .stream()
                .map(UsuarioSyncDTO::from)
                .toList();
    }
}