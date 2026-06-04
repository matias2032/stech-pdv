// ── HistoricoSenhasRepository.java ───────────────────────────────────────────
package com.stechengenharia.pdv_backend.usuario.repository;
 
import com.stechengenharia.pdv_backend.usuario.entity.HistoricoSenhas;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
 
@Repository
public interface HistoricoSenhasRepository extends JpaRepository<HistoricoSenhas, Long> {
}