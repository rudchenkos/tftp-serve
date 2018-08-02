module Main where

import Network.TFTP.Types
import Network.TFTP.Protocol
import Network.TFTP.Message
import Network.TFTP.UDPIO
import Data.Map.Lazy (Map)
import Data.List (break)
import qualified Data.Map.Lazy as M
import qualified Data.ByteString.Lazy as B
import Options.Applicative
import Options.Applicative.Help.Pretty
import Text.Printf

data Config = Config
  { configIP :: String
  , configPort :: String
  }

config :: Parser Config
config = Config <$> argument str (metavar "SERVER_IP")
                <*> strOption ( long "port" <> short 'p'
                             <> help "UDP port to listen on" <> value "69"
                             <> metavar "PORT")

main :: IO ()
main = do
  config <- execParser opts
  files <- M.fromList . parseFileSpecs <$> getContents
  -- TODO Validate that all paths exist

  printf "Starting TFTP server on %s:%s\n" (configIP config) (configPort config)
  udpIO (Just $ configIP config) (Just $ configPort config) $
    runTFTP (serve files)
  where
    opts = info (config <**> helper) (fullDesc <> progDescDoc (Just description))
    description = text "A simple TFTP server"
      <> linebreak
      <$$> text "Takes files to serve from stdin, as lines of form:"
      <$$> white (indent 4 (text "kernel:path/on/host/to/kernel.img"
                <$$> text "ramdisk:path/on/host/to/initrd.img"))
      <> linebreak
      <$$> text "which results in kernel.img being served as 'kernel'"
      <$$> text "and initrd.img served as 'ramdisk' by TFTP."

parseFileSpecs :: String -> [(String, FilePath)]
parseFileSpecs = map parseLine . lines
  where
    parseLine s = case break (==':') s of
      (name, (':':path)) -> (name, path)
      otherwise -> fail ("Invalid input line: " ++ s)

serve :: (MessageIO m address) => Map String FilePath -> XFerT m address ()
serve files = do
  req <- receive Nothing
  case req of
    Just (RRQ rfname mode) -> do
        liftIO $ printf "Client requested %s\n" rfname
        case M.lookup rfname files of
            Nothing -> do
                reply (Error FileNotFound)
                serve files
                
            Just path -> do
                resetBlockIndex
                incBlockIndex
                liftIO (B.readFile path) >>= writeData
                serve files

    Just cmd -> do
        liftIO $ printf "Unsupported command: %s\n" (show cmd)
        reply (Error IllegalTFTPOperation)

    Nothing -> liftIO $ putStrLn "Internal error: receive timeout"
     
