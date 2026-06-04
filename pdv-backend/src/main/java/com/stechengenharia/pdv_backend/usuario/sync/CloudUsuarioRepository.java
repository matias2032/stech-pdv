package com.stechengenharia.pdv_backend.usuario.sync;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface CloudUsuarioRepository extends JpaRepository<CloudUsuarioEntity, Long> {

    /**
     * Chave de idempotência: localiza pelo ID que veio da loja.
     * Usado no upsert para decidir entre INSERT e UPDATE.
     */
    Optional<CloudUsuarioEntity> findByLocalId(Long localId);

    /**
     * Usado pelo PULL: devolve tudo o que mudou após uma data.
     * O índice idx_usuario_updated_at garante performance.
     */
    List<CloudUsuarioEntity> findByUpdatedAtAfter(OffsetDateTime since);

    /**
     * Opcional — útil para dashboards ou auditoria na nuvem.
     */
    List<CloudUsuarioEntity> findByDeletedFalseAndAtivoTrue();
}