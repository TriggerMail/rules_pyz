from google.cloud.datastore_v1.proto import datastore_pb2
from google.cloud.datastore_v1.proto import datastore_pb2_grpc
import grpc
import unittest

class TestGRPCConnect(unittest.TestCase):
    def test_connect(self):
        # when zipped grpc needs to load a resource that it tries to get from disk
        # that resource must be unzipped along with the native code library
        credentials = grpc.ssl_channel_credentials()
        channel = grpc.secure_channel('datastore.googleapis.com', credentials)
        datastore_stub = datastore_pb2_grpc.DatastoreStub(channel)
        request = datastore_pb2.LookupRequest()
        with self.assertRaisesRegexp(grpc.RpcError, 'missing required authentication') as context:
            datastore_stub.Lookup(request)
        self.assertEqual(context.exception.code(), grpc.StatusCode.UNAUTHENTICATED)
