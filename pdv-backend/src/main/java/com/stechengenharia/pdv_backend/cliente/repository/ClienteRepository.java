package com.stechengenharia.pdv_backend.cliente.repository;

import com.stechengenharia.pdv_backend.cliente.entity.Cliente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

@Repository
public interface ClienteRepository extends JpaRepository<Cliente, Long> {

    // ── Unicidade (ignoram soft-deleted) ──────────────────────────────
    boolean existsByEmailAndDeletedFalse(String email);
    boolean existsByNuitAndDeletedFalse(String nuit);
    boolean existsByContactoAndDeletedFalse(String contacto);

    boolean existsByEmailAndIdNotAndDeletedFalse(String email, Long id);
    boolean existsByNuitAndIdNotAndDeletedFalse(String nuit, Long id);
    boolean existsByContactoAndIdNotAndDeletedFalse(String contacto, Long id);

    // ── Busca por ID (filtra deletados) ───────────────────────────────
@Query("SELECT c FROM Cliente c JOIN FETCH c.perfil WHERE c.id = :id AND c.deleted = false")
Optional<Cliente> findByIdComPerfil(@Param("id") Long id);

    // ── Listagem (filtra deletados) ───────────────────────────────────
   @Query("SELECT c FROM Cliente c JOIN FETCH c.perfil WHERE c.deleted = false")
List<Cliente> findAllComPerfil();

@Query("SELECT c FROM Cliente c JOIN FETCH c.perfil WHERE c.perfil.id = :idPerfil AND c.deleted = false")
List<Cliente> findByPerfilId(@Param("idPerfil") Long idPerfil);

    // ── Pesquisa (filtra deletados) ───────────────────────────────────
    @Query("""
        SELECT c FROM Cliente c JOIN FETCH c.perfil
        WHERE c.deleted = false AND (
              LOWER(COALESCE(c.nome,''))     LIKE LOWER(CONCAT('%',:termo,'%'))
           OR LOWER(COALESCE(c.apelido,''))  LIKE LOWER(CONCAT('%',:termo,'%'))
           OR LOWER(COALESCE(c.email,''))    LIKE LOWER(CONCAT('%',:termo,'%'))
           OR LOWER(COALESCE(c.contacto,'')) LIKE LOWER(CONCAT('%',:termo,'%'))
           OR LOWER(COALESCE(c.nuit,''))     LIKE LOWER(CONCAT('%',:termo,'%'))
        )""")
    List<Cliente> pesquisar(@Param("termo") String termo);

    // ── Sincronização ─────────────────────────────────────────────────
// Para sincronização: inclui também deleted=true
List<Cliente> findBySyncStatusIn(List<String> statuses);

    @Query("SELECT c FROM Cliente c WHERE c.updatedAt > :desde")
    List<Cliente> findAtualizadosDepoisDe(@Param("desde") Instant desde);
}

