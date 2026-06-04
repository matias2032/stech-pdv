package com.stechengenharia.pdv_backend.cliente.repository;

import com.stechengenharia.pdv_backend.cliente.entity.PerfilCliente;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PerfilClienteRepository extends JpaRepository<PerfilCliente, Long> {
}