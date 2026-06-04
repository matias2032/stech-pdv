package com.stechengenharia.pdv_backend.usuario.repository;

import com.stechengenharia.pdv_backend.usuario.entity.Perfil;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PerfilRepository extends JpaRepository<Perfil, Long> {
    // Métodos customizados se forem necessários no futuro (ex: findByNome)
}