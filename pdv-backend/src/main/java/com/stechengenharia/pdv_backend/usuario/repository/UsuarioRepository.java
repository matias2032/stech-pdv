package com.stechengenharia.pdv_backend.usuario.repository;

import com.stechengenharia.pdv_backend.usuario.entity.Usuario;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface UsuarioRepository extends JpaRepository<Usuario, Long> {

    // ── QUERIES OPERACIONAIS (filtram deleted = false) ────────────────

    @Query("SELECT u FROM Usuario u WHERE u.email = :email AND u.deleted = false")
    Optional<Usuario> findByEmail(@Param("email") String email);

    @Query("SELECT CASE WHEN COUNT(u) > 0 THEN true ELSE false END " +
           "FROM Usuario u WHERE u.email = :email AND u.deleted = false")
    boolean existsByEmail(@Param("email") String email);

    @Query("SELECT u FROM Usuario u WHERE u.ativo = :ativo AND u.deleted = false")
    List<Usuario> findByAtivo(@Param("ativo") Boolean ativo);

    @Query("SELECT u FROM Usuario u WHERE u.perfil.id IN :ids AND u.deleted = false")
    List<Usuario> findByPerfilIds(@Param("ids") List<Long> ids);

    @Query("SELECT u FROM Usuario u WHERE u.perfil.id IN :ids " +
           "AND u.ativo = :ativo AND u.deleted = false")
    List<Usuario> findByPerfilIdsAndAtivo(@Param("ids") List<Long> ids,
                                          @Param("ativo") Boolean ativo);

    @Query("SELECT u FROM Usuario u JOIN FETCH u.perfil " +
           "WHERE (u.email = :credencial OR u.telefone = :credencial " +
           "OR u.apelido = :credencial) AND u.deleted = false")
    Optional<Usuario> findByCredencial(@Param("credencial") String credencial);

    @Query("SELECT u FROM Usuario u JOIN FETCH u.perfil " +
           "WHERE u.id = :id AND u.deleted = false")
    Optional<Usuario> findByIdComPerfil(@Param("id") Long id);

    // ── QUERIES DE SINCRONIZAÇÃO ──────────────────────────────────────

    /**
     * Busca todos os registos que ainda não foram sincronizados com a nuvem.
     * Inclui deleted=true para que os soft-deletes sejam enviados (PENDING_DELETE).
     */
    @Query("SELECT u FROM Usuario u WHERE u.syncStatus IN :statuses")
    List<Usuario> findBySyncStatusIn(@Param("statuses") List<String> statuses);

    /**
     * Marca em lote como SYNCED após confirmação da nuvem.
     * Usa versão para evitar sobrescrever uma edição feita entre o push e o ACK.
     */
    @Modifying
    @Query("UPDATE Usuario u SET u.syncStatus = 'SYNCED' WHERE u.id IN :ids")
    void markAsSynced(@Param("ids") List<Long> ids);
}