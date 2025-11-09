import React, { useState, useEffect } from 'react';
import axios, { AxiosError } from 'axios';
import './App.css';

interface Client {
  id: number;
  name: string;
  email: string;
  phone: string;
  company: string;
}

function App() {
  const [clients, setClients] = useState<Client[]>([]);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [company, setCompany] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  
  useEffect(() => {
    fetchClients();
  }, []);

  async function fetchClients() {
    try {
      const response = await axios.get('/api/clients');
      setClients(response.data);
    } catch (error) {
      const e = error as AxiosError;
      console.error('Failed to fetch clients:', e.message);
    }
  }

  async function addClient(e: React.FormEvent) {
    e.preventDefault();
    setIsLoading(true);
    const clientData = { name, email, phone, company };
    try {
      await axios.post('/api/clients', clientData);
      fetchClients();
      // Clear form
      setName('');
      setEmail('');
      setPhone('');
      setCompany('');
    } catch (error) {
      const e = error as AxiosError;
      console.error('Failed to add client:', e.message);
      alert('Ошибка при добавлении клиента');
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="container">
      <header className="app-header">
        <h1 className="app-title">CRM System</h1>
        <p className="app-subtitle">Управление клиентами</p>
      </header>

      <div className="card">
        <h2 className="form-title">Добавить нового клиента</h2>
        <form onSubmit={addClient} className="client-form">
          <div className="form-group">
            <label className="form-label" htmlFor="name">Имя</label>
            <input
              id="name"
              className="form-input"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Введите имя"
              required
            />
          </div>
          
          <div className="form-group">
            <label className="form-label" htmlFor="email">Email</label>
            <input
              id="email"
              className="form-input"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="example@email.com"
              type="email"
              required
            />
          </div>
          
          <div className="form-group">
            <label className="form-label" htmlFor="phone">Телефон</label>
            <input
              id="phone"
              className="form-input"
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="+7 (999) 123-45-67"
            />
          </div>
          
          <div className="form-group">
            <label className="form-label" htmlFor="company">Компания</label>
            <input
              id="company"
              className="form-input"
              value={company}
              onChange={(e) => setCompany(e.target.value)}
              placeholder="Название компании"
            />
          </div>
          
          <button type="submit" className="btn-submit" disabled={isLoading}>
            {isLoading ? 'Добавление...' : 'Добавить клиента'}
          </button>
        </form>
      </div>

      <div className="card clients-section">
        <h2 className="clients-title">Список клиентов</h2>
        {clients.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">📋</div>
            <p className="empty-state-text">Клиенты пока не добавлены</p>
          </div>
        ) : (
          <div className="clients-grid">
            {clients.map((client) => (
              <div key={client.id} className="client-card">
                <h3 className="client-name">{client.name}</h3>
                <div className="client-info">
                  <div className="client-detail">
                    <span className="client-detail-icon">✉️</span>
                    {client.email}
                  </div>
                  {client.phone && (
                    <div className="client-detail">
                      <span className="client-detail-icon">📞</span>
                      {client.phone}
                    </div>
                  )}
                  {client.company && (
                    <div className="client-detail">
                      <span className="client-detail-icon">🏢</span>
                      {client.company}
                    </div>
                  )}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

export default App;