using FarmingSimulatorSDKClient.PipeLineServer.Interfaces;
using System;
using System.IO.Pipes;
using System.Text;

namespace FarmingSimulatorSDKClient.PipeLineServer
{
    internal class InternalPipeServer : ICommunicationServer
    {
        #region private fields

        private readonly NamedPipeServerStream pipeServer;
        private bool isStopping;
        private readonly object lockingObject = new object();
        private const int BufferSize = 2048;
        public readonly string Id;

        private class Info
        {
            public readonly byte[] Buffer;
            public readonly StringBuilder StringBuilder;

            public Info()
            {
                Buffer = new byte[BufferSize];
                StringBuilder = new StringBuilder();
            }
        }

        #endregion

        #region c'tor
        public InternalPipeServer(string pipeName, int maxNumberOfServerInstances)
        {
            pipeServer = new NamedPipeServerStream(pipeName, PipeDirection.In, maxNumberOfServerInstances,
                PipeTransmissionMode.Message, PipeOptions.Asynchronous);
            Id = Guid.NewGuid().ToString();
        }

        #endregion

        #region events

        public event EventHandler<ClientConnectedEventArgs> ClientConnectedEvent;
        public event EventHandler<ClientDisconnectedEventArgs> ClientDisconnectedEvent;
        public event EventHandler<MessageReceivedEventArgs> MessageReceivedEvent;

        #endregion

        #region public methods

        public string ServerId
        {
            get { return Id; }
        }

        /// <summary>
        /// This method begins an asynchronous operation to wait for a client to connect.
        /// </summary>
        public void Start()
        {
            try
            {
                pipeServer.BeginWaitForConnection(WaitForConnectionCallBack, null);
            }
            catch (Exception ex)
            {
                throw;
            }
        }

        /// <summary>
        /// This method disconnects, closes and disposes the server
        /// </summary>
        public void Stop()
        {
            isStopping = true;

            try
            {
                if (pipeServer.IsConnected)
                {
                    pipeServer.Disconnect();
                }
            }
            catch (Exception ex)
            {
                throw;
            }
            finally
            {
                pipeServer.Close();
                pipeServer.Dispose();
            }
        }

        #endregion

        #region private methods

        /// <summary>
        /// This method begins an asynchronous read operation.
        /// </summary>
        private void BeginRead(Info info)
        {
            try
            {
                pipeServer.BeginRead(info.Buffer, 0, BufferSize, EndReadCallBack, info);
            }
            catch (Exception ex)
            {
                throw;
            }
        }

        /// <summary>
        /// This callback is called when the async WaitForConnection operation is completed,
        /// whether a connection was made or not. WaitForConnection can be completed when the server disconnects.
        /// </summary>
        private void WaitForConnectionCallBack(IAsyncResult result)
        {
            if (!isStopping)
            {
                lock (lockingObject)
                {
                    if (!isStopping)
                    {
                        // Call EndWaitForConnection to complete the connection operation
                        pipeServer.EndWaitForConnection(result);

                        OnConnected();

                        BeginRead(new Info());
                    }
                }
            }
        }

        /// <summary>
        /// This callback is called when the BeginRead operation is completed.
        /// We can arrive here whether the connection is valid or not
        /// </summary>
        private void EndReadCallBack(IAsyncResult result)
        {
            var readBytes = pipeServer.EndRead(result);
            if (readBytes > 0)
            {
                var info = (Info)result.AsyncState;

                // Get the read bytes and append them
                info.StringBuilder.Append(Encoding.UTF8.GetString(info.Buffer, 0, readBytes));

                if (!pipeServer.IsMessageComplete) // Message is not complete, continue reading
                {
                    BeginRead(info);
                }
                else // Message is completed
                {
                    // Finalize the received string and fire MessageReceivedEvent
                    var message = info.StringBuilder.ToString().TrimEnd('\0');

                    OnMessageReceived(message);

                    // Begin a new reading operation
                    BeginRead(new Info());
                }
            }
            else // When no bytes were read, it can mean that the client have been disconnected
            {
                if (!isStopping)
                {
                    lock (lockingObject)
                    {
                        if (!isStopping)
                        {
                            OnDisconnected();
                            Stop();
                        }
                    }
                }
            }
        }

        /// <summary>
        /// This method fires MessageReceivedEvent with the given message
        /// </summary>
        private void OnMessageReceived(string message)
        {
            if (MessageReceivedEvent != null)
            {
                MessageReceivedEvent(this,
                    new MessageReceivedEventArgs
                    {
                        Message = message
                    });
            }
        }

        /// <summary>
        /// This method fires ConnectedEvent 
        /// </summary>
        private void OnConnected()
        {
            if (ClientConnectedEvent != null)
            {
                ClientConnectedEvent(this, new ClientConnectedEventArgs { ClientId = Id });
            }
        }

        /// <summary>
        /// This method fires DisconnectedEvent 
        /// </summary>
        private void OnDisconnected()
        {
            if (ClientDisconnectedEvent != null)
            {
                ClientDisconnectedEvent(this, new ClientDisconnectedEventArgs { ClientId = Id });
            }
        }

        #endregion
    }
}
