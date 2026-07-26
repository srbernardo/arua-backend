class OrderConfirmationJob < ApplicationJob
  queue_as :default

  def perform(order_id)
    order = Order.find(order_id)
    user = order.user
    items = order.order_items.includes(:product, :variant)

    store_email = ENV.fetch("STORE_EMAIL", "")
    return if store_email.blank?

    items_html = items.map do |item|
      "<tr>
        <td style='padding:8px;border-bottom:1px solid #eee;'>#{item.quantity}x</td>
        <td style='padding:8px;border-bottom:1px solid #eee;'>#{item.product.name}</td>
        <td style='padding:8px;border-bottom:1px solid #eee;'>#{item.variant.size} / #{item.variant.color}</td>
        <td style='padding:8px;border-bottom:1px solid #eee;text-align:right;'>#{item.unit_price.to_f} €</td>
        <td style='padding:8px;border-bottom:1px solid #eee;text-align:right;'>#{(item.unit_price * item.quantity).to_f} €</td>
      </tr>"
    end.join

    html = <<~HTML
      <div style='font-family:Arial,sans-serif;max-width:600px;margin:0 auto;'>
        <h2 style='color:#1a1a1a;'>Novo Pedido ##{order.order_number}</h2>
        <p style='color:#666;'><strong>Data:</strong> #{order.created_at.strftime('%d/%m/%Y %H:%M')}</p>
        <p style='color:#666;'><strong>Cliente:</strong> #{user.name} (#{user.phone})</p>

        <h3 style='color:#1a1a1a;margin-top:24px;'>Itens do Pedido</h3>
        <table style='width:100%;border-collapse:collapse;'>
          <thead>
            <tr style='background:#f5f5f5;'>
              <th style='padding:8px;text-align:left;'>Qtd</th>
              <th style='padding:8px;text-align:left;'>Produto</th>
              <th style='padding:8px;text-align:left;'>Tamanho/Cor</th>
              <th style='padding:8px;text-align:right;'>Preço Unit.</th>
              <th style='padding:8px;text-align:right;'>Subtotal</th>
            </tr>
          </thead>
          <tbody>
            #{items_html}
          </tbody>
        </table>

        <div style='margin-top:16px;text-align:right;'>
          <p style='color:#666;'>Subtotal: #{order.subtotal} €</p>
          <p style='color:#666;'>Frete: #{order.shipping} €</p>
          <p style='color:#1a1a1a;font-size:18px;font-weight:bold;'>Total: #{order.total} €</p>
        </div>

        <div style='margin-top:24px;padding:16px;background:#f9f9f9;border-radius:8px;'>
          <h3 style='color:#1a1a1a;margin:0 0 8px 0;'>Detalhes de Pagamento e Entrega</h3>
          <p style='color:#666;margin:4px 0;'><strong>Pagamento:</strong> #{order.payment_method == 'mbway' ? 'MB Way' : 'Dinheiro'}</p>
          <p style='color:#666;margin:4px 0;'><strong>Morada:</strong> #{order.address_street}</p>
          <p style='color:#666;margin:4px 0;'><strong>Localidade:</strong> #{order.address_city}, #{order.address_state}</p>
          <p style='color:#666;margin:4px 0;'><strong>Código Postal:</strong> #{order.address_zip}</p>
        </div>
      </div>
    HTML

    Resend::Emails.send({
      from: "Bikini Store <onboarding@resend.dev>",
      to: [store_email],
      subject: "Novo Pedido ##{order.order_number} - #{user.name}",
      html: html
    })
  end
end
