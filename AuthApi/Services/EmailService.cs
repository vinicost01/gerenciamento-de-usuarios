using System.Net;
using System.Net.Mail;

namespace AuthApi.Services
{
    public interface IEmailService
    {
        Task SendEmailAsync(string toEmail, string subject, string body);
    }

    public class EmailService : IEmailService
    {
        private readonly IConfiguration _configuration;
        private readonly ILogger<EmailService> _logger;

        public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
        {
            _configuration = configuration;
            _logger = logger;
        }

        public async Task SendEmailAsync(string toEmail, string subject, string body)
        {
            var smtpServer = _configuration["EmailSettings:SmtpServer"];
            var smtpPort = int.Parse(_configuration["EmailSettings:SmtpPort"] ?? "587");
            var senderEmail = _configuration["EmailSettings:SenderEmail"];
            var senderPassword = _configuration["EmailSettings:SenderPassword"];

            if (string.IsNullOrEmpty(smtpServer) || string.IsNullOrEmpty(senderEmail))
            {
                _logger.LogError("Configurações de email (SMTP) incompletas no appsettings.json");
                throw new Exception("Servidor de email não configurado.");
            }

            try
            {
                using (var client = new SmtpClient(smtpServer, smtpPort))
                {
                    client.EnableSsl = true; 
                    client.UseDefaultCredentials = false;

                    if (!string.IsNullOrEmpty(senderPassword))
                    {
                        client.Credentials = new NetworkCredential(senderEmail, senderPassword);
                    }
                    else
                    {
                        client.Credentials = null;
                    }

                    var mailMessage = new MailMessage
                    {
                        From = new MailAddress(senderEmail, "Suporte NovaLink"),
                        Subject = subject,
                        Body = body,
                        IsBodyHtml = true
                    };
                    mailMessage.To.Add(toEmail);

                    await client.SendMailAsync(mailMessage);
                    _logger.LogInformation($"Email enviado com sucesso para {toEmail} via {smtpServer}");
                }
            }
            catch (Exception ex)
            {
                _logger.LogError($"Erro ao enviar email: {ex.Message}");
                throw; 
            }
        }
    }
}