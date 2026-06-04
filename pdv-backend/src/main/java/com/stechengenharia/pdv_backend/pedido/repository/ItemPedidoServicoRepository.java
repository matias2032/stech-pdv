package com.stechengenharia.pdv_backend.pedido.repository;

import com.stechengenharia.pdv_backend.pedido.entity.ItemPedidoServico;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

/**
 * Repositório dedicado para itens de serviço de um pedido.
 * Mantido no módulo pedido porque ItemPedidoServico é uma entidade
 * de composição do pedido, não do catálogo de serviços.
 */
@Repository
public interface ItemPedidoServicoRepository extends JpaRepository<ItemPedidoServico, Integer> {

    /** Todos os itens de serviço de um pedido específico. */
    List<ItemPedidoServico> findByPedido_IdPedido(Integer idPedido);

    /**
     * Busca um item garantindo que pertence ao pedido indicado.
     * Equivalente ao findByIdItemPedidoAndPedidoIdPedido já existente
     * no ItemPedidoRepository para produtos.
     */
    Optional<ItemPedidoServico> findByIdItemServicoAndPedido_IdPedido(
            Integer idItemServico, Integer idPedido);

    /** Remove todos os itens de serviço de um pedido (usado no cancelamento se necessário). */
    @Modifying
    @Query("DELETE FROM ItemPedidoServico i WHERE i.pedido.idPedido = :idPedido")
    void deleteByPedido_IdPedido(@Param("idPedido") Integer idPedido);

    /** Verifica se um serviço do catálogo tem itens associados (antes de desactivar). */
    boolean existsByServico_IdServico(Integer idServico);
}