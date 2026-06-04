package com.stechengenharia.pdv_backend.pedido.repository;
import com.stechengenharia.pdv_backend.pedido.entity.TipoPagamento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TipoPagamentoRepository extends JpaRepository<TipoPagamento, Integer> {}