using FarmingSimulatorSDKClient.PipeLineServer.Interfaces;
using FarmingSimulatorSDKClient.PipeLineServer.Utilities;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace FarmingSimulatorSDKClient.PipeLineServer
{
    internal class PipeServer : ICommunicationServer
    {
        #region private fields

        private readonly string pipeName;
        private readonly SynchronizationContext synchronizationContext;
        private readonly IDictionary<string, ICommunicationServer> servers;
        private const int MaxNumberOfServerInstances = 10;

        #endregion

        #region c'tor

        public PipeServer(string pipeName)
        {
            this.pipeName = pipeName;
            synchronizationContext = AsyncOperationManager.SynchronizationContext;
            servers = new ConcurrentDictionary<string, ICommunicationServer>();
        }

        #endregion

        #region events

        public event EventHandler<MessageReceivedEventArgs> MessageReceivedEvent;
        public event EventHandler<ClientConnectedEventArgs> ClientConnectedEvent;
        public event EventHandler<ClientDisconnectedEventArgs> ClientDisconnectedEvent;

        #endregion

        #region ICommunicationServer implementation

        public string ServerId
        {
            get { return pipeName; }
        }

        public void Start()
        {
            StartNamedPipeServer();
        }

        public void Stop()
        {
            foreach (var server in servers.Values)
            {
                try
                {
                    UnregisterFromServerEvents(server);
                    server.Stop();
                }
                catch (Exception)
                {
                    throw;
                }
            }

            servers.Clear();
        }

        #endregion

        #region private methods

        private void StartNamedPipeServer()
        {
            var server = new InternalPipeServer(pipeName, MaxNumberOfServerInstances);
            servers[server.Id] = server;

            server.ClientConnectedEvent += ClientConnectedHandler;
            server.ClientDisconnectedEvent += ClientDisconnectedHandler;
            server.MessageReceivedEvent += MessageReceivedHandler;

            server.Start();
        }

        private void StopNamedPipeServer(string id)
        {
            UnregisterFromServerEvents(servers[id]);
            servers[id].Stop();
            servers.Remove(id);
        }

        private void UnregisterFromServerEvents(ICommunicationServer server)
        {
            server.ClientConnectedEvent -= ClientConnectedHandler;
            server.ClientDisconnectedEvent -= ClientDisconnectedHandler;
            server.MessageReceivedEvent -= MessageReceivedHandler;
        }

        private void OnMessageReceived(MessageReceivedEventArgs eventArgs)
        {
            synchronizationContext.Post(e => MessageReceivedEvent.SafeInvoke(this, (MessageReceivedEventArgs)e),
                eventArgs);
        }

        private void OnClientConnected(ClientConnectedEventArgs eventArgs)
        {
            synchronizationContext.Post(e => ClientConnectedEvent.SafeInvoke(this, (ClientConnectedEventArgs)e),
                eventArgs);
        }

        private void OnClientDisconnected(ClientDisconnectedEventArgs eventArgs)
        {
            synchronizationContext.Post(
                e => ClientDisconnectedEvent.SafeInvoke(this, (ClientDisconnectedEventArgs)e), eventArgs);
        }

        private void ClientConnectedHandler(object sender, ClientConnectedEventArgs eventArgs)
        {
            OnClientConnected(eventArgs);

            StartNamedPipeServer();
        }

        private void ClientDisconnectedHandler(object sender, ClientDisconnectedEventArgs eventArgs)
        {
            OnClientDisconnected(eventArgs);

            StopNamedPipeServer(eventArgs.ClientId);
        }

        private void MessageReceivedHandler(object sender, MessageReceivedEventArgs eventArgs)
        {
            OnMessageReceived(eventArgs);
        }

        #endregion
    }
}
