package com.stechengenharia.pdv_backend.pedido.repository;
import com.stechengenharia.pdv_backend.pedido.entity.PedidoCancelamento;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;



@Repository
public interface PedidoCancelamentoRepository extends JpaRepository<PedidoCancelamento, Integer> {

    Optional<PedidoCancelamento> findByPedidoIdPedido(Integer idPedido);
}